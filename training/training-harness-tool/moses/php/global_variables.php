<?php

//////////////////////////////////////////////////////////////////////////////////////
//
//��� Copyright 2012 Adobe Systems Incorporated
//
//��� This file is part of TMX to Moses Corpus Tool.
//�
//��� TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//��� it under the terms of the GNU Lesser General Public License as published by the 
//��� Free Software Foundation, either version 3 of the License, or (at your option) 
//��� any later version.
//�
//��� TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//��� but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//��� or FITNESS FOR A PARTICULAR PURPOSE.� See the GNU General Public License for 
//��� more details.
//�
//��� You should have received a copy of the GNU Lesser General Public License along 
//�� �with TMX to Moses Corpus Tool.� If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////

$SUDO              = "/usr/bin/sudo";
$BASH              = "/bin/bash";

$ROOT_DIR          = dirname(dirname(__FILE__));

$LOG_PATH          = "/tmp/";
$LOG_FILE          = $LOG_PATH . "moses_" . posix_getpid() . ".log";

$TRAIN_SCRIPT_PATH = "/tools/bin/";
$TRAIN_SCRIPT_NAME = "adobe-moses-train.sh";

// $TRAIN_CONFIG_PATH = $ROOT_DIR . "/config/";
$TRAIN_CONFIG_NAME = "train_config.cfg";

$EVAL_SCRIPT_PATH = "/tools/bin/";
$EVAL_SCRIPT_NAME = "adobe-moses-evaluation.sh";

// $EVAL_CONFIG_PATH = $ROOT_DIR . "/config/";
$EVAL_CONFIG_NAME = "evaluation_config.cfg";

$TRAIN_DATA_ROOT = "/data/";

// $ID                = "id";
// $TRAINING          = "flag_training";
// $TUNING            = "flag_tuning";
// $RECASING          = "flag_recaser";
// $LM_FACTOR         = "lm_factor";
// $LM_ORDER          = "lm_order";
// $SRC_LANG          = "src";
// $TAR_LANG          = "target";
// $TRAIN_CORPUS      = "corpus_training";
// $TUNE_CORPUS       = "corpus_tuning";
// $ALIGNMENT         = "alignement";
// $REORDER           = "reordering";
// $IRSTLM            = "with_irstlm";
// $KENLM             = "with_kenlm";

?>