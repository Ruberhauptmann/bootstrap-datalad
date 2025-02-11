set -e -u

###############################################################################
#                               HOW TO USE                                    #
#                                                                             #
#       Please adjust every variable within a "FIXME" markup to your          #
#       filesystem, data, and software container.                             #
#       Depending on which job scheduling system you use, comment out         #
#       or remove the irrelevant system (optional).                           #
#       More information about this script can be found in the README.        #
#                                                                             #
###############################################################################


# Jobs are set up to not require a shared filesystem (except for the lockfile)
# ------------------------------------------------------------------------------
# FIXME: Supply a RIA-URL to a RIA store that will collect all outputs, and a
# RIA-URL to a different RIA store from which the dataset will be cloned from.
# Both RIA stores will be created if they don't yet exist.
output_store="ria+file:///superscratch/tsievers/output_store"
input_store="ria+file:///superscratch/tsievers/input_store"


#-------------------------------------------------------------------------------
# FIXME: Replace this name with a dataset name of your choice.
source_ds="master-thesis-calculations"
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# Create a source dataset with all analysis components as an analysis access
# point.
datalad create -c yoda $source_ds
cd $source_ds


# create dedicated input and output locations. Results will be pushed into the
# output sibling and the analysis will start with a clone from the input sibling.
datalad create-sibling-ria --new-store-ok -s output "${output_store}"
pushremote=$(git remote get-url --push output)
datalad create-sibling-ria --new-store-ok -s input --storage-sibling off "${input_store}"

# register the input dataset
datalad clone -d . ${data} inputs/data
# amend the previous commit with a nicer commit message
git commit --amend -m 'Register input data dataset as a subdataset'

mkdir logs
echo logs >> .gitignore


################################################################################
# SLURM SETUP START
################################################################################

echo .SLURM_datalad_lock >> .gitignore

# cleanup - we have generated the job definitions, we do not need to keep a
# massive input dataset around. Having it around wastes resources and makes many
# git operations needlessly slow
datalad uninstall -r --nocheck inputs/data

# make sure the fully configured output dataset is available from the designated
# store for initial cloning and pushing the results.
datalad push --to input
datalad push --to output

# if we get here, we are happy
echo SUCCESS
