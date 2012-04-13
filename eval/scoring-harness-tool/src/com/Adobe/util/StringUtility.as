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


package com.Adobe.util
{	
	import mx.collections.ArrayCollection;
	import mx.core.INavigatorContent;

	public class StringUtility
	{
		public function StringUtility()
		{
		}
		
		public function String2Boolean(string:String):Boolean
		{
			var boolValue:Boolean;
			
			if (string == "yes")
			{
				boolValue = true;
			}
			else if (string == "no")
			{
				boolValue = false;
			}
			
			return boolValue;
		}
		
		
		public function string2ArrListCol(string:String):ArrayCollection
		{
//			var regExp_NIST:RegExp = /NIST score = +(\d+\.?\d+) +BLEU score = +(\d+\.?\d+) for system "(.*)"/g;
			var regExp_NIST:RegExp = /(NIST score = +)(\d+\.?\d+)/g;
			var regExp_BLEU:RegExp = /(BLEU score = +)(\d+\.?\d+)/g;
			var regExp_sys:RegExp = /(for system ")(.*)(")/g;
			var regExp_METEOR:RegExp = /(Final score: +)(\d+\.?\d+)/g;
			var regExp_TER:RegExp =/(Total TER:) +(\d+\.?\d+) +\(\d+\.?\d+\/\d+\.?\d+\)/g;
			
			var methods:Array = new Array("NIST", "BLEU", "METEOR", "TER");
			
			var nistRawResult:Array = string.match(regExp_NIST);
			var bleuRawResult:Array = string.match(regExp_BLEU);
			var sysRawResult:Array = string.match(regExp_sys);
			var meteorRawResult:Array = string.match(regExp_METEOR);
			var terRawResult:Array = string.match(regExp_TER);
			
			var nistResult:Array = new Array();
			var bleuResult:Array = new Array();
			var sysResult:Array = new Array();
			var meteorResult:Array = new Array();
			var terResult:Array = new Array();
			
			for each (var item:Object in nistRawResult)
			{ 				
				nistResult.push(item.toString().replace(regExp_NIST, "$2"));
			}
			
			trace(nistResult);
			
			for each (item in bleuRawResult)
			{
				bleuResult.push(item.toString().replace(regExp_BLEU, "$2"));
			}
			
			trace(bleuResult);
			
			for each (item in sysRawResult)
			{
				sysResult.push(item.toString().replace(regExp_sys, "$2"));
			}
			
			trace(sysResult);
			
			for each (item in meteorRawResult)
			{ 
				meteorResult.push(item.toString().replace(regExp_METEOR, "$2"));
			}
			
			trace(meteorResult);
			
			for each (item in terRawResult)
			{ 
				terResult.push(item.toString().replace(regExp_TER, "$2"));
			}
			
			trace(terResult);
			
			var finalScore:Array = new Array();
			finalScore.push(nistResult,bleuResult,meteorResult,terResult);
			
			var finalResult:Array = new Array();
			trace(methods.length);
			for (var i:int = 0; i < methods.length; i++ )
			{
				var tmpArr:Object = new Object();
				tmpArr["method"] = methods[i];
				
				for (var j:int = 0; j < nistResult.length; j++ )
				{
					tmpArr[sysResult[j]] = finalScore[i][j];
					trace(finalScore[i][j]);
				}
				
				finalResult.push(tmpArr);
				
			}
			
			finalResult.push(sysResult);

			var arrCol:ArrayCollection = new ArrayCollection();
			
			arrCol.source = finalResult;
			
			return arrCol;
		}

	}
}