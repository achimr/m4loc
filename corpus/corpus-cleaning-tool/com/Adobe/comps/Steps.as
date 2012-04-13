//////////////////////////////////////////////////////////////////////////////////////
//
//    Copyright 2012 Adobe Systems Incorporated
//
//    This file is part of TMX to Moses Corpus Tool.
// 
//    TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Lesser General Public License as published by the 
//    Free Software Foundation, either version 3 of the License, or (at your option) 
//    any later version.
// 
//    TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
//    more details.
// 
//    You should have received a copy of the GNU Lesser General Public License along 
//    with TMX to Moses Corpus Tool.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////


package com.Adobe.comps
{
	import com.Adobe.comps.stepBox.*;
	import com.Adobe.managers.ProcessConfigManager;
	import com.Adobe.util.StringUtility;
	
	import flash.filesystem.File;
	import flash.utils.Dictionary;

	public class Steps
	{
		private var _processConfigMgr:ProcessConfigManager = ProcessConfigManager.getInstance();
		
//		//********************************
//		//* Default steps difined in XML *
//		//
//		private var phtag_clean:XML = new XML("<phtag_clean />");
//		
//		private var url_clean:XML = new XML("<url_clean />");
//		
//		private var tokenize:XML = new XML("<tokenize />");
//		
//		private var lowercase:XML = new XML("<lowercase />");
//		
//		private var num_clean:XML = new XML("<num_clean />");
//		
//		private var dup_clean:XML = new XML("<dup_clean restrict="False" />");
//		
//		private var extra_long_clean:XML = new XML("<extra_long_clean><source>30</source><target>30</target></extra_long_clean>");
//		
//		private var weird_align_clean:XML = new XML("<weird_align_clean><diff>10</diff></weird_align_clean>");
		
		//********************************
		//* Step Box Definitions *
		//
		private var phtag_clean_box:CleanPlaceholders = new CleanPlaceholders();

		private var url_clean_box:CleanURLs = new CleanURLs();
		
		private var tokenize_box:Tokenize = new Tokenize();
		
		private var lowercase_box:Lowercase = new Lowercase();
		
		private var num_clean_box:CleanNumbers = new CleanNumbers();
		
		private var dup_clean_box:FilterDuplicateLines = new FilterDuplicateLines();
		
		private var extra_long_clean_box:FilterLongLines = new FilterLongLines();
		
		private var weird_align_clean_box:FilterWeirdPairs = new FilterWeirdPairs();
		
		private var _strUtil:StringUtility = new StringUtility();
		
		public var stepMap:Dictionary = new Dictionary();
		
		public function Steps(targLang:String = "")
		{
			var process:XML = _processConfigMgr.getProcess(targLang);
			
			trace(process);
			
			stepMap[process.descendants("phtag_clean")[0].toXMLString()] = phtag_clean_box;
			stepMap[process.descendants("url_clean")[0].toXMLString()] = url_clean_box;
			stepMap[process.descendants("tokenize")[0].toXMLString()] = tokenize_box;
			stepMap[process.descendants("lowercase")[0].toXMLString()] = lowercase_box;
			stepMap[process.descendants("num_clean")[0].toXMLString()] = num_clean_box;
			stepMap[process.descendants("dup_clean")[0].toXMLString()] = dup_clean_box;
			stepMap[process.descendants("extra_long_clean")[0].toXMLString()] = extra_long_clean_box;
			stepMap[process.descendants("weird_align_clean")[0].toXMLString()] = weird_align_clean_box;
			
			phtag_clean_box.id = "cln_ph";
			url_clean_box.id = "cln_url";
			tokenize_box.id = "tokenize";
			lowercase_box.id = "lowercase";
			num_clean_box.id = "cln_num";
			dup_clean_box.id = "flt_dup";
			extra_long_clean_box.id = "flt_long";
			weird_align_clean_box.id = "flt_weird";
			
			phtag_clean_box.defaultOrder = process.descendants("phtag_clean")[0].childIndex() + 1;
			url_clean_box.defaultOrder = process.descendants("url_clean")[0].childIndex() + 1;
			tokenize_box.defaultOrder = process.descendants("tokenize")[0].childIndex() + 1;
			lowercase_box.defaultOrder = process.descendants("lowercase")[0].childIndex() + 1;
			num_clean_box.defaultOrder = process.descendants("num_clean")[0].childIndex() + 1;
			dup_clean_box.defaultOrder = process.descendants("dup_clean")[0].childIndex() + 1;
			extra_long_clean_box.defaultOrder = process.descendants("extra_long_clean")[0].childIndex() + 1;
			weird_align_clean_box.defaultOrder = process.descendants("weird_align_clean")[0].childIndex() + 1;
			
			phtag_clean_box.selected = _strUtil.String2Boolean(process.descendants("phtag_clean")[0].@enable);
			url_clean_box.selected = _strUtil.String2Boolean(process.descendants("url_clean")[0].@enable);
			tokenize_box.selected = _strUtil.String2Boolean(process.descendants("tokenize")[0].@enable);
			lowercase_box.selected = _strUtil.String2Boolean(process.descendants("lowercase")[0].@enable);
			num_clean_box.selected = _strUtil.String2Boolean(process.descendants("num_clean")[0].@enable);
			dup_clean_box.selected = _strUtil.String2Boolean(process.descendants("dup_clean")[0].@enable);
			extra_long_clean_box.selected = _strUtil.String2Boolean(process.descendants("extra_long_clean")[0].@enable);
			weird_align_clean_box.selected = _strUtil.String2Boolean(process.descendants("weird_align_clean")[0].@enable);

			dup_clean_box.includeDiffTarget = !_strUtil.String2Boolean(process.descendants("dup_clean")[0].@restrict);
			extra_long_clean_box.sourceThreshold = process.descendants("extra_long_clean")[0].source;
			extra_long_clean_box.targetThreshold = process.descendants("extra_long_clean")[0].target;
			weird_align_clean_box.threshold = process.descendants("weird_align_clean")[0].diff;

		}	
	}
}