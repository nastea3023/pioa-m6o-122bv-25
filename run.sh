xrun +access+rwc +xm64bit +timeout_us=300000 +max_err_count=10 -timescale 1ns/1ps -f ./../uvm2026/tb_files.lst \
-l log.log -linedebug -sv -seed random -nowarn CUVIHR +REG_TEST +ARBITER_ROUND_TEST +ARBITER_TARGET_TEST +ARBITER_PRIOR_TEST +CORE_TEST +DATA_REG_TEST +FIFO_TEST +CORE_INTERRUPT_TEST +ARBITER_INTR_TEST +FIFO_INTERRUPT_TEST +RESET_ON_THE_FLY_TEST #-gui
