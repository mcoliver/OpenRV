#!/usr/bin/env python

# *****************************************************************************
# Copyright (c) 2020 Autodesk, Inc.
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# *****************************************************************************
import argparse
import concurrent.futures
import logging
import os
import pathlib
from pathlib import Path
import subprocess
import threading
import shutil
import stat


future_lock = threading.Lock()

# Configure logging.
logging.basicConfig(format="-- %(message)s")
logger = logging.getLogger().setLevel(logging.INFO)


def get_object_files(target):
    target = Path(target)

    if target.is_dir():
        for root, dirs, files in os.walk(target):
            for f in files:
                path = Path(root) / f
                # Skip symlinks to avoid infinite loops or processing same file twice
                if path.is_symlink():
                    continue

                try:
                    file_type = subprocess.check_output(["file", "-bh", str(path)])
                    if file_type.startswith(b"Mach-O"):
                        yield str(path.absolute())
                except subprocess.CalledProcessError:
                    pass
    else:
        yield target


def get_rpaths(object_file_path):
    try:
        otool_output = subprocess.check_output(["otool", "-l", object_file_path]).decode().splitlines()
    except subprocess.CalledProcessError:
        return

    i = 0
    while i < len(otool_output):
        otool_line = otool_output[i].strip()
        i += 1

        if otool_line == "":
            continue

        if otool_line.split()[-1] == "LC_RPATH":
            for y in range(i, i + 2):
                if y >= len(otool_output): break
                rpath_line = otool_output[y].split()

                if len(rpath_line) > 1 and rpath_line[0] == "path":
                    yield rpath_line[1]
                    break


def get_shared_library_paths(object_file_path):
    try:
        otool_output = subprocess.check_output(["otool", "-L", object_file_path]).decode().splitlines()
    except subprocess.CalledProcessError:
        return

    i = 0

    while i < len(otool_output):
        otool_line = otool_output[i].strip()
        i += 1
        if "(compatibility version" in otool_line:
            yield otool_line.split("(compatibility")[0].strip()


def delete_rpath(object_file_path, rpath):
    delete_rpath_command = [
        "install_name_tool",
        "-delete_rpath",
        rpath,
        object_file_path,
    ]
    result = subprocess.run(delete_rpath_command, capture_output=True, text=True)
    # Don't fail if the rpath doesn't exist (can happen during incremental rebuilds)
    if result.returncode != 0:
        if "no LC_RPATH load command" not in result.stderr:
            logging.warning(f"Failed to delete rpath {rpath} from {object_file_path}: {result.stderr}")
        else:
            logging.info(f"\tRpath {rpath} not found in {object_file_path}, skipping")
            return False
    return True

def change_shared_library_path(object_file_path, old_library_path):
    new_library_path = f"@rpath/{os.path.basename(old_library_path)}"

    change_shared_library_path_command = [
        "install_name_tool",
        "-change",
        old_library_path,
        new_library_path,
        object_file_path,
    ]
    result = subprocess.run(change_shared_library_path_command, capture_output=True, text=True)
    if result.returncode != 0:
        logging.error(f"Failed to change install name: {result.stderr}")
        raise subprocess.CalledProcessError(result.returncode, change_shared_library_path_command, result.stdout, result.stderr)

    return new_library_path


def get_bundle_lib_dir(object_file_path):
    path = pathlib.Path(object_file_path)
    for parent in path.parents:
        if parent.name == "Contents":
            lib_dir = parent / "lib"
            if not lib_dir.exists():
                try:
                    lib_dir.mkdir(parents=True, exist_ok=True)
                except OSError:
                    return None
            return lib_dir
    return None


def is_system_lib(lib_path):
    return lib_path.startswith("/usr/lib") or lib_path.startswith("/System/Library")


def get_file_type(path):
    try:
        return subprocess.check_output(["file", "-bh", str(path)]).decode()
    except:
        return ""

def sign_file(file_path):
    try:
        # Ad-hoc signing
        subprocess.run(["codesign", "--force", "--sign", "-", str(file_path)], check=True, capture_output=True)
        logging.info(f"\tSigned {file_path}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to sign {file_path}: {e.stderr.decode()}")

def fix_rpath(target, root):
    # Ensure target is writable
    try:
        st = os.stat(target)
        os.chmod(target, st.st_mode | stat.S_IWUSR)
    except OSError:
        logging.warning(f"Could not make {target} writable.")

    for file in get_object_files(target):
        logging.info(f"Inspecting file: {file}")
        
        needs_signing = False

        # Removed numpy skip check to ensure comprehensive coverage

        # Prevent delete the same rpath multiple time (e.g. MacOS fat binary).
        deletedRPATH = []
        for rpath in get_rpaths(file):
            output = f"\trpath: {rpath}"

            if rpath.startswith("@") is False and rpath.startswith(".") is False and rpath not in deletedRPATH:
                if delete_rpath(file, rpath):
                    needs_signing = True
                deletedRPATH.append(rpath)
                output += " (Deleted)"

            logging.info(output)

        logging.info(f"Fixing shared library paths for {file}")

        file_type = get_file_type(file)
        is_dylib = "shared library" in file_type
        
        libs = list(get_shared_library_paths(file))
        if not libs: 
            if needs_signing:
                sign_file(file)
            continue
        
        bundle_lib_dir = get_bundle_lib_dir(file)
        
        start_index = 0
        if is_dylib:
             # First entry is ID
             old_id = libs[0]
             start_index = 1
             
             # Fix ID if needed (only if absolute and not system)
             if os.path.isabs(old_id) and not is_system_lib(old_id):
                 # Fix ID
                 new_id = f"@rpath/{os.path.basename(old_id)}"
                 try:
                     subprocess.run(["install_name_tool", "-id", new_id, file]).check_returncode()
                     logging.info(f"\tUpdated ID from {old_id} to {new_id}")
                     needs_signing = True
                 except Exception as e:
                     logging.error(f"Failed to update ID: {e}")

        # Fix Dependencies
        for library_path in libs[start_index:]:
            output = f"\tlibrary path: {library_path}"

            shared_library_name = os.path.basename(library_path)
            
            # Identify if we need to fix this path
            needs_fix = False
            
            # Check if it is a system library
            if is_system_lib(library_path):
                continue

            # If it is absolute, we almost certainly want to fix it
            if os.path.isabs(library_path):
                needs_fix = True
            elif library_path == shared_library_name:
                 # Bare filename, safer to convert to @rpath
                 needs_fix = True
            
            if needs_fix:
                # If it's an external absolute path (not in the bundle already), copy it.
                if os.path.isabs(library_path) and os.path.exists(library_path) and bundle_lib_dir:
                     dest_path = bundle_lib_dir / shared_library_name
                     
                     if not dest_path.exists():
                         logging.info(f"\tCopying {library_path} to {dest_path}")
                         try:
                             shutil.copy2(library_path, dest_path)
                             # Ensure writable
                             os.chmod(dest_path, os.stat(dest_path).st_mode | stat.S_IWUSR)
                             
                             # Recursively fix the copied library
                             fix_rpath(str(dest_path), root)
                             # Note: fix_rpath will sign the copied file itself
                         except Exception as e:
                             logging.error(f"Failed to copy {library_path}: {e}")

                try:
                    new_library_path = change_shared_library_path(file, library_path)
                    output += f" (Changed to {new_library_path})"
                    needs_signing = True
                except Exception as e:
                     logging.error(f"Error changing path for {library_path}: {e}")

            logging.info(output)
            
        if needs_signing:
            sign_file(file)


def read_paths_from_file(file_path):
    paths = []
    with open(file_path, "r") as file:
        for line in file:
            paths.append(line.strip())  # strip() removes newline characters
    return paths


def fix_rpath_with_lock(path, root_dir):
    with future_lock:
        return fix_rpath(str(path), str(root_dir))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--file", type=pathlib.Path, dest="file", help="Target to sanitize")
    parser.add_argument("--files-list", type=pathlib.Path, dest="files_list", help="Files to sanitize")
    parser.add_argument("--root", type=pathlib.Path, dest="root_dir", help="Root directory", required=True)

    args = parser.parse_args()

    if args.file is None and args.files_list is None:
        parser.error("At least one of --file or --files-list is required.")

    if args.file and args.file.exists() is False:
        raise FileNotFoundError(f"Unable to locate {args.file.absolute()}")
    elif args.files_list and args.files_list.exists() is False:
        raise FileNotFoundError(f"Unable to locate {args.files_list.absolute()}")
    if args.root_dir.exists() is False:
        raise FileNotFoundError(f"Unable to locate {args.root_dir.absolute()}")

    if args.file:
        # Direct file processing
        fix_rpath(str(args.file), str(args.root_dir.resolve().absolute()))
        
    elif args.files_list:
        paths = read_paths_from_file(str(args.files_list.resolve().absolute()))
        with concurrent.futures.ThreadPoolExecutor() as executor:
            # Create a list of futures for each path to be processed.
            futures = [
                executor.submit(fix_rpath_with_lock, pathlib.Path(path), args.root_dir.resolve().absolute())
                for path in paths
            ]
            for future in concurrent.futures.as_completed(futures):
                try:
                    result = future.result()
                except Exception as e:
                    logging.error(f"Error processing path: {result}, Error: {e}")
                    raise e
