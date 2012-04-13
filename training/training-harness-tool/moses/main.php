<?php

//////////////////////////////////////////////////////////////////////////////////////
//
//ÊÊÊ Copyright 2012 Adobe Systems Incorporated
//
//ÊÊÊ This file is part of TMX to Moses Corpus Tool.
//Ê
//ÊÊÊ TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//ÊÊÊ it under the terms of the GNU Lesser General Public License as published by the 
//ÊÊÊ Free Software Foundation, either version 3 of the License, or (at your option) 
//ÊÊÊ any later version.
//Ê
//ÊÊÊ TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//ÊÊÊ but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//ÊÊÊ or FITNESS FOR A PARTICULAR PURPOSE.Ê See the GNU General Public License for 
//ÊÊÊ more details.
//Ê
//ÊÊÊ You should have received a copy of the GNU Lesser General Public License along 
//ÊÊ Êwith TMX to Moses Corpus Tool.Ê If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////

require_once("./php/run_moses_script.php");
require_once("./php/output.php");

global $LOG_FILE;

switch ($_POST["name"])
{
	case "Train":
		$args = array(
		"flag_training" => 1,
		"flag_tuning" => 0,
		"flag_recaser" => 0,
		"id" => $_POST["train_id"],
		"lm_factor" => $_POST["lm_factor"],
		"lm_order" => $_POST["lm_order"],
	    "src" => $_POST["src_lang"],
	    "target" => $_POST["tar_lang"],
	    "corpus_training" => $_POST["train_corpus_name"],
	    "corpus_tuning" => $_POST["tune_corpus_name"],
	    "alignment" => $_POST["alignment"],
	    "reordering" => $_POST["reordering"],
	    "with_irstlm" => $_POST["irstlm"],
	    "with_kenlm" => $_POST["kenlm"]
        );
		saveConfig(getTrainingConfigFullPath(), $args);
		MosesCmdRun(getTrainingScriptFullPath(), getTrainingConfigFullPath());
		print($LOG_FILE);
		break;
		
	case "Tune":
		$args = array(
		"flag_training" => 0,
		"flag_tuning" => 1,
		"flag_recaser" => 0,
		"id" => $_POST["train_id"],
		"lm_factor" => $_POST["lm_factor"],
		"lm_order" => $_POST["lm_order"],
	    "src" => $_POST["src_lang"],
	    "target" => $_POST["tar_lang"],
	    "corpus_training" => $_POST["train_corpus_name"],
	    "corpus_tuning" => $_POST["tune_corpus_name"],
	    "alignment" => $_POST["alignment"],
	    "reordering" => $_POST["reordering"],
	    "with_irstlm" => $_POST["irstlm"],
	    "with_kenlm" => $_POST["kenlm"]
        );
		saveConfig(getTrainingConfigFullPath(), $args);
		MosesCmdRun(getTrainingScriptFullPath(), getTrainingConfigFullPath());
		print($LOG_FILE);
		break;
		
	case "Train+Tune":
		$args = array(
		"flag_training" => 1,
		"flag_tuning" => 1,
		"flag_recaser" => 0,
		"id" => $_POST["train_id"],
		"lm_factor" => $_POST["lm_factor"],
		"lm_order" => $_POST["lm_order"],
	    "src" => $_POST["src_lang"],
	    "target" => $_POST["tar_lang"],
	    "corpus_training" => $_POST["train_corpus_name"],
	    "corpus_tuning" => $_POST["tune_corpus_name"],
	    "alignment" => $_POST["alignment"],
	    "reordering" => $_POST["reordering"],
	    "with_irstlm" => $_POST["irstlm"],
	    "with_kenlm" => $_POST["kenlm"]
        );
		saveConfig(getTrainingConfigFullPath(), $args);
		MosesCmdRun(getTrainingScriptFullPath(), getTrainingConfigFullPath());
		print($LOG_FILE);
		break;

	case "Evaluate":
		$args = array(
		"id" => $_POST["train_id"],
		"flag_recaser" => $_POST["recasing"],
		"flag_evaluation" => $_POST["evaluate"],
	    "src" => $_POST["src_lang"],
	    "target" => $_POST["tar_lang"],
	    "corpus_recaser" => $_POST["recase_corpus_name"],
	    "corpus_eval_src" => $_POST["eval_src_corpus_name"],
	    "corpus_eval_ref" => $_POST["eval_ref_corpus_name"],
	    "corpus_eval_tst" => $_POST["eval_tst_corpus_name"],
	    "evaluation_tool" => $_POST["evaluation_tool"]
        );
		saveConfig(getEvaluationConfigFullPath(), $args);
		MosesCmdRun(getEvaluationScriptFullPath(), getEvaluationConfigFullPath());
		print($LOG_FILE);
		break;
		
	case "getTrainingList":
	    print(getTrainingList($_POST["src_lang"], $_POST["tar_lang"]));
	    break;

	case "getAllResults":
	    print(getEvalResults($_POST["src_lang"], $_POST["tar_lang"]));
	    break;

	case "getResult":
		getLog($_POST["log_file"]);
		break;
}

return 0;

?>
