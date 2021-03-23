#!/bin/bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

cfg=${1:-finetune_tacotron2.v5}

train_config=conf/tuning/${cfg}.yaml
inference_config=conf/decode.yaml

# reset_layers="tts.enc.embed,tts.dec.feat_out,tts.dec.prob_out"
reset_layers="tts.enc.embed,normalize"

init_param=downloads/3b0a779f28d99232479e782d4d20292b/exp/tts_train_tacotron2_raw_phn_tacotron_g2p_en_no_space/199epoch.pth
tag="ljspeech_${cfg}"

# espnet_model_zoo_download kan-bayashi/ljspeech_tacotron2 --cachedir downloads --unpack true

./tts.sh \
    --lang nl \
    --token_type char \
    --cleaner none \
    --g2p none \
    --train_config "${train_config}" \
    --inference_config "${inference_config}" \
    --train_set train_nodev \
    --valid_set train_dev \
    --fs 22050 \
    --test_sets "train_dev" \
    --srctexts "data/train/text" \
    --train_args "--init_param ${init_param}:::${reset_layers} --use_wandb true" \
    --tag "${tag}" --stage 8 --stop_stage 8 --skip_upload false  # "$@"
