%{
indexing

	description:

		""

	author:     "Sven Ehrke <sven.ehrke@ubs.com>"
	license:    "Eiffel Forum Freeware License v1 (see forum.txt)"
	note:	    "Based on mexp source"

deferred class XF_PARSER
	inherit

		YY_PARSER_SKELETON [ANY]
			rename
				make as make_parser_skeleton
			redefine
				report_error
			end

		XF_SCANNER
			rename
				make as make_xml_scanner
			end

		XM_ERROR_CODES

feature {ANY}

%}

%token T_LT T_GT T_SLASH T_COLON T_EQUAL T_DOUBLE_QUOTES
%token T_LT_SL T_SL_GT T_LT_QM T_QM_GT T_XML T_START_COMMENT T_END_COMMENT

%token <UC_STRING> T_TEXT
%token <UC_STRING> T_WORD
%token <UC_STRING> T_NS_WORD
%token <UC_STRING> T_ATTR_TEXT
%token <UC_STRING> T_PI_CONTENT
%token <UC_STRING> T_COMMENT_CONTENT

%type <UC_STRING>	xml_attr_value
%type <UC_STRING>	xml_decl_version

%type <DS_PAIR [UC_STRING, UC_STRING]>	xml_attr_name
%type <DS_PAIR [DS_PAIR [UC_STRING, UC_STRING],UC_STRING]>	xml_attr
%type <DS_LINKED_LIST [DS_PAIR [DS_PAIR [UC_STRING, UC_STRING],UC_STRING]]> xml_attr_list

%start xml_document

%%

----------------
xml_document:
	-- nothing
	| xml_element
	| xml_decl xml_element
	| xml_decl xml_pis xml_element
        ;

----------------
xml_pis:
	xml_pi
	|xml_pis xml_pi
	;

----------------
xml_decl:
	T_LT_QM T_XML xml_decl_version T_QM_GT { on_xml_declaration ($3, empty_ucstring, True) }
	;

----------------
xml_decl_version:
	T_WORD T_EQUAL T_DOUBLE_QUOTES T_ATTR_TEXT T_DOUBLE_QUOTES { $$ := $4 }
	;

----------------
p_text:
        T_TEXT { on_content ($1) }
        ;

----------------
xml_element_content:
        -- nothing
        | xml_element_content xml_element 
        | xml_element_content p_text
        | xml_element_content xml_pi
        | xml_element_content xml_comment
        ;

----------------
xml_element:
        xml_empty_tag
        |xml_start_tag xml_element_content xml_end_tag
        ;


----------------
xml_empty_tag:
          T_LT T_WORD xml_attr_list T_SL_GT
          {
  		on_start_tag ($2, empty_ucstring, $3)
  		on_end_tag ($2, empty_ucstring)
		
          }
          |T_LT T_NS_WORD xml_attr_list T_SL_GT
          {
  		tmp_uc_pair := split_name_and_prefix ($2)
  		on_start_tag (tmp_uc_pair.first, tmp_uc_pair.second, $3)
  		on_end_tag (tmp_uc_pair.first, tmp_uc_pair.second)
          }
          ;

----------------
xml_start_tag:
          -- only the start tag can contain a namespace
          T_LT T_WORD xml_attr_list T_GT
          {
  		on_start_tag ($2, empty_ucstring, $3)
          }
          |
          T_LT T_NS_WORD xml_attr_list T_GT
          {
  		tmp_uc_pair := split_name_and_prefix ($2)
  		on_start_tag (tmp_uc_pair.first, tmp_uc_pair.second, $3)
          }
          ;

----------------
xml_end_tag:
          T_LT_SL T_WORD T_GT
          {
  		on_end_tag ($2, empty_ucstring)
          }
  	|
          T_LT_SL T_NS_WORD T_GT
          {
  		tmp_uc_pair := split_name_and_prefix ($2)
  		on_end_tag (tmp_uc_pair.first, tmp_uc_pair.second)
          }
          ;

----------------
xml_attr_list: 
	-- empty
	{ 
		!! $$.make 
	}
	| xml_attr_list xml_attr
	{
		$$ := $1
		$$.put_last ($2)
        }
        ;

----------------
xml_attr: 
	xml_attr_name T_EQUAL xml_attr_value
        {
		!! $$.make ($1, $3)
        }
        ;

----------------
xml_attr_name: 
	T_WORD
        {
		!!$$.make ($1, empty_ucstring)
        }
  	| T_NS_WORD
  	{
  		tmp_uc_pair := split_name_and_prefix ($1)
  		!!$$.make (tmp_uc_pair.first, tmp_uc_pair.second)
  	}
        ;

----------------
xml_attr_value: 
	T_DOUBLE_QUOTES T_ATTR_TEXT T_DOUBLE_QUOTES
        {
		$$ := $2
        }
        ;

----------------
xml_pi: 
	T_LT_QM T_WORD T_QM_GT 
	{
		on_processing_instruction ($2, empty_ucstring)
	} 
	|T_LT_QM T_WORD T_PI_CONTENT T_QM_GT 
	{
		on_processing_instruction ($2, $3)
	} 
  	; 

----------------
xml_comment:
	T_START_COMMENT T_COMMENT_CONTENT T_END_COMMENT
	{
		on_comment ($2)
	}
	;
%%
feature {ANY} -- creation

	make is
		      -- Create parser
		do
			make_xml_scanner
			make_parser_skeleton
		end

	parse_file (a_file: like INPUT_STREAM_TYPE) is
			    --	Parse from `a_file'
		   require
			a_file_not_void: a_file /= Void
			a_file_open_read: INPUT_STREAM_.is_open_read (a_file)
		   do
			set_input_buffer (new_file_buffer (a_file))
			parse
		   end

	parse_string (a_string: STRING) is
			-- Parse from `a_string'.
		require
			a_string_not_void: a_string /= Void
		do
			set_input_buffer (new_string_buffer (a_string))
			parse
		end

feature {ANY} -- Error Handling
	report_error (m: STRING) is
		     do
			print ("found error at:")
			print (line)
			print (", ")
			print (column)
			print (": ")
			print (m)
			print ("%N")
		     end
feature {NONE} -- Helper functions
	tmp_uc_pair: DS_PAIR [UC_STRING, UC_STRING]

	uc_collon: UC_CHARACTER is
		once
			Result.make_from_character (':')
		end

	split_name_and_prefix (str: UC_STRING): DS_PAIR [UC_STRING, UC_STRING] is
			-- seperate name from prefix and return a pair
			-- (name, prefix)
		require
			str_not_void: str /= Void
		local
			n: INTEGER
		do
			n := str.index_of (uc_collon, 1)			
			check
				n_not_zero: n /= 0
			end
			!! Result.make (str.substring (n + 1, str.count), str.substring (1, n - 1))
		end

	empty_ucstring: UC_STRING is
		do
			!! Result.make (0)
		end

feature {ANY} -- Access

feature {ANY} -- Debuging
feature	{NONE} -- temp vars for actions
feature

	on_start_tag (a_name, ns_prefix: UC_STRING; attributes: DS_BILINEAR [DS_PAIR [DS_PAIR [UC_STRING, UC_STRING], UC_STRING]]) is
		deferred
		end
   
	on_end_tag (a_name, a_prefix: UC_STRING) is
		deferred
		end

	on_content (chr_data: UC_STRING) is
		deferred
		end

	on_xml_declaration (xml_version, encoding: UC_STRING; standalone: BOOLEAN) is
		deferred
		end

	on_processing_instruction (target, data: UC_STRING) is
		deferred
		end

	on_comment (com: UC_STRING) is
		deferred
		end

	handle_error (err: INTEGER) is
		deferred
		end

end

