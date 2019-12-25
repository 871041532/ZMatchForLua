

local DirtyWordFilter = class("DirtyWordFilter")

local CharMaxValue = 65535
local IntMaxValue = 2147483647

function DirtyWordFilter:ctor()
	self.hash = {}  -- <string,int>
	self.fastCheck = {}	-- byte[char.MaxValue] 
	self.fastLength = {}	-- byte[char.MaxValue] 
	self.charCheck = {} 	-- BitArray[char.MaxValue]
	self.endCheck = {}  -- BitArray[char.MaxValue]
	for i=1,CharMaxValue do
		table.insert(self.fastCheck, 0)
		table.insert(self.fastLength, 0)
		table.insert(self.charCheck, false)
		table.insert(self.endCheck, false)
	end
	self.maxWordLength = 0  -- int
	self.minWordLength = IntMaxValue  -- int
	self._replaceString = "*"  -- string
	self._fastReplaces = {}  -- string[16]
	for i=1,16 do
		table.insert(self._fastReplaces, nil)
	end
	self._newWord = ""  -- string


end


public class DirtyWordFilter
{


	
	public void ResetMaxLength(int length)
	{
		if(length != null && length > 0)
			_fastReplaces = new string[length];
	}
	
	#region 初始化数据,将List集合类型敏感词放入HashSet中
	/// <summary>
	/// 初始化数据,将敏感词放入HashSet中
	/// </summary>
	/// <param name="badwords"></param>
	[DoNotToLua]
	public void Init (List<BadWordEntity> badwords)
	{
		foreach (BadWordEntity word in badwords) {
			maxWordLength = Math.Max (maxWordLength, word.BadWord.Length);
			minWordLength = Math.Min (minWordLength, word.BadWord.Length);
			for (int i = 0; i < 7 && i < word.BadWord.Length; i++) {
				fastCheck [word.BadWord [i]] |= (byte)(1 << i);
			}
			
			for (int i = 7; i < word.BadWord.Length; i++) {
				fastCheck [word.BadWord [i]] |= 0x80;
			}
			
			if (word.BadWord.Length == 1) {
				charCheck [word.BadWord [0]] = true;
			} else {
				fastLength [word.BadWord [0]] |= (byte)(1 << (Math.Min (7, word.BadWord.Length - 2)));
				endCheck [word.BadWord [word.BadWord.Length - 1]] = true;
			}
		}
	}
	
	#endregion
	
	
	#region 初始化数据,将String[]类型敏感词放入HashSet中
	/// <summary>
	/// 初始化数据,将敏感词放入HashSet中
	/// </summary>
	/// <param name="badwords"></param>
	public void InitStringArray (string[] badwords, int type)
	{
		foreach (string word in badwords) {
			InitString(word,type);
		}
	}
	
	#endregion

	#region 初始化数据,将String[]类型敏感词放入HashSet中
	/// <summary>
	/// 初始化数据,将敏感词放入HashSet中
	/// </summary>
	/// <param name="badwords"></param>
	public void InitString (string word, int type)
	{
		int wordLength = word.Length;
		char cc = _replaceString [0];
		char first = word [0];
		if (_fastReplaces.Length > wordLength && _fastReplaces [wordLength] == null) {
			_fastReplaces [wordLength] = _replaceString.PadRight (wordLength, cc);
		}
		maxWordLength = Math.Max (maxWordLength, wordLength);
		minWordLength = Math.Min (minWordLength, wordLength);
		for (int i = 0; i < 7 && i < wordLength; i++) {
			fastCheck [word [i]] |= (byte)(1 << i);
		}
			
		for (int i = 7; i < wordLength; i++) {
			fastCheck [word [i]] |= 0x80;
		}
			
		if (word.Length == 1) {
			charCheck [first] = true;
		} else {
			fastLength [first] |= (byte)(1 << (Math.Min (7, word.Length - 2)));
			endCheck [word [word.Length - 1]] = true;
		}
		if (hash.ContainsKey (word) == false)
			hash.Add (word, type);
		else {
			hash [word] |= type;
		}
	}
	
	#endregion
	
	
	
	#region 检查是否有敏感词
	/// <summary>
	/// 检查是否有敏感词
	/// </summary>
	/// <param name="text"></param>
	/// <returns></returns>
	public bool HasBadWord (string text, int types)
	{
		return SearchBadWord (text, types) != -1;
	}

	/// <summary>
	/// 查找敏感词的索引位置
	/// </summary>
	/// <param name="text"></param>
	/// <returns></returns>
	public int SearchBadWord (string text, int types)
	{
		int index = 0;
		int hashedType = 0;
		while (index < text.Length) {
			int count = 1;
			if ((fastCheck [text [index]] & 1) == 0) {
				while (index < text.Length - 1 && (fastCheck[text[++index]] & 1) == 0)
					;
			}
			
			char begin = text [index];
			if (minWordLength == 1 && charCheck [begin]) {
				if ((hash [begin.ToString ()] & types) > 0)
					return index;
				else {
					index++;
					continue;
				}
			}
			for (int j = 1; j <= Math.Min(maxWordLength, text.Length - index - 1); j++) {
				char current = text [index + j];
				
				if ((fastCheck [current] & (1 << Math.Min (j, 7))) == 0) {
					break;
				}
				
				if (j + 1 >= minWordLength) {
					if ((fastLength [begin] & (1 << Math.Min (j - 1, 7))) > 0 && endCheck [current]) {
						string sub = text.Substring (index, j + 1);
						if (hash.ContainsKey (sub)) {
							if ((hash [sub] & types) > 0)
								return index;
						}
					}
				}
			}
			index ++;
		}
		return -1;
	}
	
	#endregion
	
	
	
	#region 替换敏感词
	/// <summary>
	/// 替换敏感词
	/// </summary>
	/// <param name="text"></param>
	/// <returns></returns>
	public string ReplaceBadWord (string text, int types)
	{
		int index = 0;
		int hashedType = 0;
		char begin;
		for (index = 0; index < text.Length; index++) {
			if ((fastCheck [text [index]] & 1) == 0) {
				while (index < text.Length - 1 && (fastCheck[text[++index]] & 1) == 0)
					;
			}
			//单字节检测
			begin = text [index];
			if (minWordLength == 1 && charCheck [begin]) {
				if ((hash [begin.ToString ()] & types) > 0) {
					text = text.Replace (begin, _replaceString [0]);
					continue;
				}
			}
			
			//多字节检测
			for (int j = 1; j <= Math.Min(maxWordLength, text.Length - index - 1); j++) {
				//快速排除
				if ((fastCheck [text [index + j]] & (1 << Math.Min (j, 7))) == 0) {
					break;
				}
				
				if (j + 1 >= minWordLength && _fastReplaces.Length > j + 1) {
					string sub = text.Substring (index, j + 1);
					
					if (hash.ContainsKey (sub)) {
						if ((hash [sub] & types) > 0) {
							//替换字符操作
							text = text.Replace (sub, _fastReplaces [(j + 1)]);
							//记录新位置
							index += j;
							break;
						}
					}
				}
			}
		}
		_newWord = text;
		return text;
	}
	#endregion
}

#region 敏感词实体类
/// <summary>
/// 敏感词实体
/// </summary>
public class BadWordEntity
{
	/// <summary>
	/// 敏感词
	/// </summary>
	public string BadWord { get; set; }
}

#endregion