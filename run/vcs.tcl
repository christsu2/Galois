# TCL file invoked from VCS's simv at run-time using this: -ucli -do <this file>

# Syntax: fsdbDumpfile FSDB_Name [Limit_Size]
fsdbDumpfile "waves.fsdb"

# Syntax: fsdbDumpvars [depth] [instance] [option]*
##############################################################################
# Option                     Description
##############################################################################
# +mda                       Dumps memory and MDA signals in all scopes.
# +packedmda                 Dumps packed signals
# +struct                    Dumps structs
# +skip_cell_instance=mode  Enables or disables cell dumping
# +strength                  Enables strength dumping
# +parameter                 Dumps parameters
# +power                     Dumps power-related signals
# +trace_process             Dumps VHDL processes
# +no_functions              Disables dumping of functions
# +sva                       Dumps assertions
# +Reg_Only                  Dumps only reg type signals
# +IO_Only                   Dumps only IO port signals
# +by_file=<filename>        File to specify objects to add
# +all                       Dumps memories, MDA signals, structs, unions,power, and packed structs
dump -aggregates -add top
fsdbDumpvars 0 top +all +trace_process +mda
fsdbDumpSVA 0 top.dummy

run
quit


run
quit
