package
{
	public class NumberString
	{
		private var m_prefix: String = "";
		private var m_suffix: String = "";
		
		private var m_value: Number = 0;
		private var m_text: String = "0";
		
		private var object: *;
		private var property: String;
		
		public function NumberString (startValue: Number = 0, prefix: String = "", suffix: String = "")
		{
			m_prefix = prefix;
			m_suffix = suffix;
			m_value = startValue;
			
			update();
		}
		
		public function bind (obj: *, prop: String = "text"): void
		{
			object = obj;
			property = prop;
			
			update();
		}
		
		public function get text (): String
		{
			return m_text;
		}
		
		public function set value(_value: int): void
		{
			if (_value == m_value) { return; }
			m_value = _value;
			update();
		}
		
		public function get value(): int
		{
			return m_value;
		}
		
		public function set prefix(_value: String): void
		{
			if (_value == m_prefix) { return; }
			m_prefix = _value;
			update();
		}
		
		public function get prefix(): String
		{
			return m_prefix;
		}
		
		public function set suffix(_value: String): void
		{
			if (_value == m_suffix) { return; }
			m_suffix = _value;
			update();
		}
		
		public function get suffix(): String
		{
			return m_suffix;
		}
		
		public function update (): void
		{
			m_text = m_prefix + String(m_value) + m_suffix;
			
			if (object) {
				object[property] = m_text;
			}
		}
	}
}

