# import collections

lines = open("_build/.ninja_log").readlines()[1:]
data = [l.split() for l in lines]
data = [(int(d[1]) - int(d[0]), d[3]) for d in data]
data.sort(reverse=True)
[print(f"{t / 1000.0:>8.2f}s | {n}") for t, n in data[:20]]
