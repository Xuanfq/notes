# CPU

## Diagnosis

### Preparation

#### /proc/cpuinfo

CPU信息：`/proc/cpuinfo`

```sh
~# cat /proc/cpuinfo
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 0
cpu cores       : 4
apicid          : 0
initial apicid  : 0
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 1
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 1
cpu cores       : 4
apicid          : 2
initial apicid  : 2
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 2
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 2
cpu cores       : 4
apicid          : 4
initial apicid  : 4
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 3
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 3
cpu cores       : 4
apicid          : 6
initial apicid  : 6
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 4
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 0
cpu cores       : 4
apicid          : 1
initial apicid  : 1
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 5
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 1
cpu cores       : 4
apicid          : 3
initial apicid  : 3
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 6
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 2
cpu cores       : 4
apicid          : 5
initial apicid  : 5
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

processor       : 7
vendor_id       : GenuineIntel
cpu family      : 6
model           : 86
model name      : Intel(R) Xeon(R) CPU D-1627 @ 2.90GHz
stepping        : 5
microcode       : 0xe000012
cpu MHz         : 2900.256
cache size      : 6144 KB
physical id     : 0
siblings        : 8
core id         : 3
cpu cores       : 4
apicid          : 7
initial apicid  : 7
fpu             : yes
fpu_exception   : yes
cpuid level     : 20
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb invpcid_single kaiser tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdseed adx smap intel_pt xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local ibpb ibrs stibp dtherm ida arat pln pts
bugs            : cpu_meltdown spectre_v1 spectre_v2
bogomips        : 5800.51
clflush size    : 64
cache_alignment : 64
address sizes   : 46 bits physical, 48 bits virtual
power management:

~# 
```

#### CPU寄存器读写(Model-Specific Registers, MSR)

前提条件：`ls /dev/cpu/*/msr`, `*`为CPU核心ID（0-n），若无，则需安装`msr`模块，`modprobe msr`/`insmod msr`

读写方法：

1. 直接读写msr文件

```sh
# read
sudo dd if=/dev/cpu/0/msr of=msr_value.bin bs=8 count=1 seek=0x198
hexdump msr_value.bin
# write
echo -n "\x00\x00\x06\x00\x00\x00\x00\x00" | sudo dd of=/dev/cpu/0/msr bs=8 seek=0x199
```

or 用编程语言进行读写


2. 通过`rdmsr`/`wrmsr`命令工具

```sh
~# apt-get install -y msr-tools
~# rdmsr -h
Usage: rdmsr [options] regno
  --help         -h  Print this help
  --version      -V  Print current version
  --hexadecimal  -x  Hexadecimal output (lower case)
  --capital-hex  -X  Hexadecimal output (upper case)
  --decimal      -d  Signed decimal output
  --unsigned     -u  Unsigned decimal output
  --octal        -o  Octal output
  --c-language   -c  Format output as a C language constant
  --zero-pad     -0  Output leading zeroes
  --raw          -r  Raw binary output
  --all          -a  all processors
  --processor #  -p  Select processor number (default 0)
  --bitfield h:l -f  Output bits [h:l] only
~# wrmsr -h
Usage: wrmsr [options] regno value...
  --help         -h  Print this help
  --version      -V  Print current version
  --all          -a  all processors
  --processor #  -p  Select processor number (default 0)
~# rdmsr -p 0 0x1b
fee00d00
~# rdmsr -p 1 0x1b
fee00c00
```


#### mprime

mprime（Prime95/Mersenne Prime Search）是一款专业的CPU 稳定性测试工具，常用于检测处理器在高负载下的稳定性，也被用于寻找梅森素数（Mersenne Primes）

硬件条件：
- 确保 CPU 散热良好（建议使用风冷或水冷散热器）。
- 准备充足电源（测试时功耗可能翻倍）。
软件条件：
- 关闭其他占用 CPU 的程序（如游戏、编译工具等）。
- 以管理员 /root 权限运行，避免权限不足导致测试中断。
硬件风险：
- 长时间高负载测试可能加速硬件老化，建议控制测试时长

```sh
~# ./mprime -h
Usage: mprime [-cdhmstv] [-aN] [-wDIR]
-c      Contact the PrimeNet server, then exit.
-d      Print detailed information to stdout.
-h      Print this.
-m      Menu to configure mprime.
-s      Display status.
-t      Run the torture test.
-v      Print the version number.
-aN     Use an alternate set of INI and output files (obsolete).
-wDIR   Run from a different working directory.

~# ./mprime -d -t
[Main thread Feb 5 00:22] Mersenne number primality test program version 29.4
[Main thread Feb 5 00:22] Optimizing for CPU architecture: Core i3/i5/i7, L2 cache size: 256 KB, L3 cache size: 6 MB
[Main thread Feb 5 00:22] Starting workers.
[Worker #2 Feb 5 00:22] Worker starting
[Worker #3 Feb 5 00:22] Worker starting
[Worker #4 Feb 5 00:22] Worker starting
[Worker #5 Feb 5 00:22] Worker starting
[Worker #2 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #2 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #7 Feb 5 00:22] Worker starting
[Worker #3 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #3 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #8 Feb 5 00:22] Worker starting
[Worker #4 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #4 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #6 Feb 5 00:22] Worker starting
[Worker #7 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #7 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #8 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #8 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #6 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #6 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #5 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #5 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #1 Feb 5 00:22] Worker starting
[Worker #1 Feb 5 00:22] Beginning a continuous self-test on your computer.
[Worker #1 Feb 5 00:22] Please read stress.txt.  Hit ^C to end this test.
[Worker #1 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #2 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #6 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #5 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #8 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #4 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #3 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #7 Feb 5 00:22] Test 1, 36000 Lucas-Lehmer iterations of M7998783 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #3 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #8 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #4 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #7 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #5 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #6 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #2 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Worker #1 Feb 5 00:28] Test 2, 36000 Lucas-Lehmer iterations of M7798785 using FMA3 FFT length 400K, Pass1=320, Pass2=1280, clm=4.
[Main thread Feb 5 00:29] Stopping all worker threads.
[Worker #3 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #3 Feb 5 00:29] Worker stopped.
[Worker #2 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #2 Feb 5 00:29] Worker stopped.
[Worker #4 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #4 Feb 5 00:29] Worker stopped.
[Worker #1 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #1 Feb 5 00:29] Worker stopped.
[Worker #6 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #6 Feb 5 00:29] Worker stopped.
[Worker #5 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #5 Feb 5 00:29] Worker stopped.
[Worker #8 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #8 Feb 5 00:29] Worker stopped.
[Worker #7 Feb 5 00:29] Torture Test completed 1 tests in 6 minutes - 0 errors, 0 warnings.
[Worker #7 Feb 5 00:29] Worker stopped.
[Main thread Feb 5 00:29] Execution halted.
```


### 诊断方法

- 检查CPU信息
  - 核心数
  - 频率
  - 型号
  - 供应商
- 读写寄存器 （Option）
- 稳定性测试
  - `./mprime -d -t`: 0 errors, 0 warnings
