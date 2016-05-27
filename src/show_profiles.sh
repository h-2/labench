#!/bin/sh

show_profiles()
{
    for PROGRAMMODE in BLASTN BLASTP BLASTX TBLASTN TBLASTX; do
        echo "Available ${PROGRAMMODE} modules with profiles:"
        echo "-----------------------------------------------"

        for MODULE in $(ls "${BENCHDIR}/modules/"); do

            if [ ! -f "${BENCHDIR}/modules/${MODULE}/labench.sh" ]; then
                echo "ERROR: Module ${MODULE} does not contain a script."
#                 exit 100
                continue
            fi

            # load module
            PROFILES=""
            . "${BENCHDIR}/modules/${MODULE}/labench.sh"
            getProfiles
            echo "${MODULE}: ${PROFILES}"
        done
        echo ""

    done
}
