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


package com.Adobe.config
{
	import com.Adobe.managers.LanguageManager;
	import com.Adobe.vo.ChineseSegmentationStandard;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class UserConfig extends EventDispatcher
	{
		private static var _instance:UserConfig;
		
		private var _mosesPath:String;
		private var _langMgr:LanguageManager = LanguageManager.getInstance();
		private var _exportPath:String = File.documentsDirectory.nativePath;
		private var _coreLang:String = _langMgr.allLanguages.getItemAt(0).toString();
		private var _chsSegmenterPath:String = File.documentsDirectory.nativePath;
		private var _chsSegmentationStandard:String;
		private var _chsSegmentationStandardDesc:String;
		private var _chsSegmentationStandards:ArrayCollection = new ArrayCollection();
		
		public function UserConfig()
		{
			if(_instance != null){
				throw new Error("Singleton!");
			}
			
			setChsSegmentationStandards();
			
			_chsSegmentationStandard = chsSegmentationStandards[0].id;
			_chsSegmentationStandardDesc = chsSegmentationStandards[0].description;
		}
		
		public static function getInstance():UserConfig{
			if (_instance == null){
				_instance = new UserConfig();
			}
			return _instance;
		}
		
		public function set mosesPath(path:String):void
		{
			_mosesPath = path;
			dispatchEvent(new Event("mosesPathChanged"));
		}
		
		[Bindable(event="mosesPathChanged")]
		public function get mosesPath():String
		{
			return _mosesPath;
		}
		
		public function set exportPath(path:String):void
		{
			_exportPath = path;
			dispatchEvent(new Event("exportPathChanged"));
		}
		
		[Bindable(event="exportPathChanged")]
		public function get exportPath():String
		{
			return _exportPath;
		}
		
		public function set coreLanguage(language:String):void
		{
			_coreLang = language;
			dispatchEvent(new Event("coreLanguageChanged"));
		}
		
		[Bindable(event="coreLanguageChanged")]
		public function get coreLanguage():String
		{
			return _coreLang;
		}
		
		public function set chsSegmenterPath(path:String):void
		{
			_chsSegmenterPath = path;
			dispatchEvent(new Event("chsSegmenterPathChanged"));
		}
		
		[Bindable(event="chsSegmenterPathChanged")]
		public function get chsSegmenterPath():String
		{
			return _chsSegmenterPath;
		}
		
		public function set chsSegmentationStandard(standard:String):void
		{
			_chsSegmentationStandard = standard;
			
			for each (var item:Object in _chsSegmentationStandards)
			{
				if (item.id == standard)
				{
					_chsSegmentationStandardDesc = item.description;
				}
			}
			
			dispatchEvent(new Event("chsSegmentationStandardChanged"));
		}
		
		[Bindable(event="chsSegmentationStandardChanged")]
		public function get chsSegmentationStandard():String
		{
			return _chsSegmentationStandard;
		}
		
		public function set chsSegmentationStandardDesc(standardDesc:String):void
		{
			_chsSegmentationStandardDesc = standardDesc;
			dispatchEvent(new Event("chsSegmentationStandardChanged"));
		}
		
		[Bindable(event="chsSegmentationStandardChanged")]
		public function get chsSegmentationStandardDesc():String
		{
			return _chsSegmentationStandardDesc;
		}
		
		public function set chsSegmentationStandardsDesc(standards:ArrayCollection):void
		{
			
		}
		
		[Bindable(event="chsSegmentationStandardChanged")]
		public function get chsSegmentationStandardsDesc():ArrayCollection
		{
			var chsSegmentationStandardsC:ArrayCollection = new ArrayCollection();
			
			var chsSegmentationStandards:Array = new Array();
			
			for each (var item:Object in _chsSegmentationStandards)
			{
				chsSegmentationStandards.push(item.description);
			}
			
			chsSegmentationStandardsC.source = chsSegmentationStandards;
			
			return chsSegmentationStandardsC;
		}
		
		public function set chsSegmentationStandards(standards:ArrayCollection):void
		{
			
		}
		
		public function get chsSegmentationStandards():ArrayCollection
		{
			return _chsSegmentationStandards;
		}
		
		private function setChsSegmentationStandards():void
		{
			var standard1:ChineseSegmentationStandard = new ChineseSegmentationStandard();
			standard1.id = "ctb";
			standard1.description = "Chinese Penn Treebank standard";
			
			var standard2:ChineseSegmentationStandard = new ChineseSegmentationStandard();
			standard2.id = "pku";
			standard2.description = "Peking University standard";
			
			_chsSegmentationStandards.addItem(standard1);
			_chsSegmentationStandards.addItem(standard2);
			
		}
		
	}
}