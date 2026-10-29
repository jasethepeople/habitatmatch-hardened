import hashlib, os, statistics, time

def draw(n, winners=100):
    seed = os.urandom(32)
    ids = [i.to_bytes(16, "big") for i in range(n)]
    start = time.perf_counter_ns()
    ranked = sorted(ids, key=lambda x: hashlib.sha256(seed + x).digest())
    elapsed_ms = (time.perf_counter_ns() - start) / 1e6
    return elapsed_ms, ranked[:winners]

for n in (1_000, 10_000, 100_000, 1_000_000):
    samples = [draw(n)[0] for _ in range(3)]
    print({"entries": n, "samples_ms": [round(x, 3) for x in samples], "median_ms": round(statistics.median(samples), 3)})
