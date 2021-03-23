#!/bin/bash

set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=1
stop_stage=2

log "$0 $*"
. utils/parse_options.sh

if [ $# -ne 0 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;
. ./db.sh || exit 1;

if [ ! -e "${GRONINGS_SPRAAK}" ]; then
    log "Fill the value of 'GRONINGS_SPRAAK' of db.sh"
    exit 1
fi
gs_root=${GRONINGS_SPRAAK}

train_set="train_nodev"
train_dev="train_dev"
ndev_utt=100

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 1: Data preparation"

    [ -e data/train ] && rm -rf data/train
    mkdir -p data/train

    # set filenames
    scp=data/train/wav.scp
    utt2spk=data/train/utt2spk
    spk2utt=data/train/spk2utt
    text=data/train/text

    # make scp, utt2spk, and spk2utt
    cut -d "|" -f 1 < ${gs_root}/metadata.csv | while read -r id; do
        filename="${gs_root}/wavs/${id}.wav"

        echo "${id} ${filename}" >> ${scp}
        echo "${id} ${id}" >> ${utt2spk}
    done
    utils/utt2spk_to_spk2utt.pl ${utt2spk} > ${spk2utt}

    # make text usign the original text
    paste -d " " \
        <(cut -d "|" -f 1 < ${gs_root}/metadata.csv) \
        <(cut -d "|" -f 3 < ${gs_root}/metadata.csv) \
        > ${text}

    utils/validate_data_dir.sh --no-feats data/train
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    log "stage 2: Data subsetting"

    # check file existence
    [ -e data/${train_dev} ] && rm -rf data/${train_dev}
    [ -e data/${train_set} ] && rm -rf data/${train_set}

    utils/subset_data_dir.sh --first data/train $ndev_utt data/${train_dev}
    n=$(($(wc -l < data/train/text) - ndev_utt))
    utils/subset_data_dir.sh --last data/train ${n} data/${train_set}

    utils/validate_data_dir.sh --no-feats data/${train_dev}
    utils/validate_data_dir.sh --no-feats data/${train_set}
fi

log "Successfully finished. [elapsed=${SECONDS}s]"
