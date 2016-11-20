#!/bin/bash

urg -dir snps_work/dut.vdb -metric line -format text > /dev/null 2>&1
# sleep 1000
cat urgReport/modinfo.txt | egrep --after-context=3 "^Module : dut" > code_coverage_${1}.txt
exit 0
