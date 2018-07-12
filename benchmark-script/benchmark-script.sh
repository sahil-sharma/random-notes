#!/bin/bash
set -e
echo ""

#Reference link: https://github.com/haydenjames/bench-scripts/blob/master/README.md

#Checking for root user
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root user."
  echo ""
  exit
fi

cd /root
report_directory=/root/system-benchmarking-reports

#getting RAM of the system
system_ram=$(free -m | awk '/Mem\:/ { print $2 }')

echo -e "Creating log report directory at /root location"
mkdir $report_directory
echo ""

echo -e "Running benchmarking scripts"

#Running bench-sh-2
echo -e "Running bench-sh-2 benchmarking tool for system information, test the network and disks "
wget https://raw.githubusercontent.com/hidden-refuge/bench-sh-2/master/bench.sh
chmod +x bench.sh
./bench.sh 2>&1 | tee $report_directory/bench.log
echo ""
sleep 5

echo "[########################]"

#Running nench
echo -e "Running nench benchmarking tool for CPU and IOPs tests and IPv4/6 speedtests"
(curl -s wget.racing/nench.sh | bash; curl -s wget.racing/nench.sh | bash) 2>&1 | tee $report_directory/nench.log
echo ""
sleep 5

echo "[########################]"

#Running vpsbench
echo -e "Running VPS Benchmark on CPU and IO performance"
bash <(wget --no-check-certificate -O - https://raw.github.com/mgutz/vpsbench/master/vpsbench) 2>&1 | tee $report_directory/vpsbench.log
echo ""
sleep 5

echo "[########################]"

#Downloading vps-benchmark
echo -e "Running VPS Benchmark on disk, cpu and network"
wget http://busylog.net/FILES2DW/busytest.sh -O - -o /dev/null | bash 2>&1 | tee $report_directory/vpsbenchmark.log
echo ""
sleep 5

echo "[########################]"

#Downloading fio
echo -e "Installing fio (Flexible I/O Tester)"
apt-get install fio -y > /dev/null 2>&1
echo ""

echo -e "Doing Random write testing"
fio --name=randwrite --ioengine=libaio --iodepth=1 --rw=randwrite --bs=4k --direct=0 --size=512M --numjobs=2 --runtime=240 --group_reporting > $report_directory/fio-random-write.log
echo ""

echo -e "Doing Random read testing"
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread --bs=4k --direct=0 --size=512M --numjobs=4 --runtime=240 --group_reporting > $report_directory/fio-random-read.log
echo ""

echo -e "Doing Random Read/Write testing"
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=random_read_write.fio --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75 > $report_directory/fio-read-write-performance.log
echo ""
sleep 5

########################

#Downloading bonnie
echo -e "Installing bonnie++"
apt-get install bonnie++ -y > /dev/null 2>&1
echo ""
echo -e "Benchmarking using bonnie to measures the performance of Unix file system operations"
bonnie++ -d /tmp -r $system_ram -u root > $report_directory/bonnie.log
echo ""
sleep 5
