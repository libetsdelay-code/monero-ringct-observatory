<!-- DRAFT issue for https://github.com/Rucknium/monerod-monitor/issues
     Review before posting. Not posted automatically. -->

**Title:** Collector crashes on `mem_maxrss` with Debian's `ps`; `maxrss` is NA even with current `ps`

**1. Crash loop with Debian 12's packaged `ps`**

With `r-cran-ps` 1.7.2 (Debian 12), `ps::ps_memory_full_info()` has no `maxrss` field, so every insert into `process_info` fails:

```
Error: No value given for placeholder mem_maxrss
Execution halted
```

The `info` row is written before the crash, so the DB looks alive while `process_info` stays empty. Installing `ps` from CRAN (1.9.3) fixes the crash. Possible fixes: require `ps >= 1.9` in the README, or fill missing memory columns with `NA` before the insert.

**2. `mem_maxrss` is always NA**

With `ps` 1.9.3 the crash is gone, but `maxrss` is `NA` for the monerod process (collector running as root, monerod as another user). Peak RSS is available from the kernel as `VmHWM` in `/proc/<pid>/status`:

```
VmHWM:   4171212 kB
VmRSS:   1545496 kB
```

Since peak memory matters for the minimum-hardware question, reading `VmHWM` (Linux only) would fill this column.

Environment: commit dca7cd6, Debian 12, R 4.2, monerod v0.19.0.0-beta.3.0 (stressnet), in Docker.
