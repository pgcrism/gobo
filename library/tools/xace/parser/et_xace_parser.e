indexing

	description:

		"Xace parsers"

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2001-2002, Andreas Leitner and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class ET_XACE_PARSER

inherit

	ET_XACE_PARSER_SKELETON
		rename
			make as make_skeleton,
			make_with_factory as make_skeleton_with_factory
		end

creation

	make, make_with_factory, make_with_variables,
	make_with_variables_and_factory

feature {NONE} -- Initialization

	make (an_error_handler: like error_handler) is
			-- Create a new Xace parser.
		require
			an_error_handler_not_void: an_error_handler /= Void
		local
			a_variables: ET_XACE_VARIABLES
			a_factory: ET_XACE_AST_FACTORY
		do
			create a_variables.make
			create a_factory.make
			make_with_variables_and_factory (a_variables, a_factory, an_error_handler)
		ensure
			error_handler_set: error_handler = an_error_handler
		end

	make_with_factory (a_factory: like ast_factory; an_error_handler: like error_handler) is
			-- Create a new Xace parser using `a_factory' as AST factory.
		require
			a_factory_not_void: a_factory /= Void
			an_error_handler_not_void: an_error_handler /= Void
		local
			a_variables: ET_XACE_VARIABLES
		do
			create a_variables.make
			make_with_variables_and_factory (a_variables, a_factory, an_error_handler)
		ensure
			ast_factory_set: ast_factory = a_factory
			error_handler_set: error_handler = an_error_handler
		end

	make_with_variables (a_variables: ET_XACE_VARIABLES an_error_handler: like error_handler) is
			-- Create a new Xace parser with variables defined in `a_variables'.
		require
			a_variables_not_void: a_variables /= Void
			an_error_handler_not_void: an_error_handler /= Void
		local
			a_factory: ET_XACE_AST_FACTORY
		do
			create a_factory.make
			make_with_variables_and_factory (a_variables, a_factory, an_error_handler)
		ensure
			error_handler_set: error_handler = an_error_handler
		end

	make_with_variables_and_factory (a_variables: ET_XACE_VARIABLES;
		a_factory: like ast_factory; an_error_handler: like error_handler) is
			-- Create a new Xace parser with variables defined in `a_variables'
			-- and using `a_factory' as AST factory.
		require
			a_variables_not_void: a_variables /= Void
			a_factory_not_void: a_factory /= Void
			an_error_handler_not_void: an_error_handler /= Void
		local
			an_expat_parser_factory: XM_EXPAT_PARSER_FACTORY
		do
			error_handler := an_error_handler
			ast_factory := a_factory
			create parsed_libraries.make (10)
				-- We must not create a new ET_XACE_LIBRARY_PARSER
				-- object if `Current' is one already, or we will
				-- recurse in this routine forever.
			library_parser ?= Current
			if library_parser = Void then
				create library_parser.make_with_variables_and_factory (a_variables, a_factory, an_error_handler)
				library_parser.set_parsed_libraries (parsed_libraries)
			end
			create xml_preprocessor.make (a_variables, error_handler)
			create xml_validator.make (an_error_handler)
				-- Use an Expat parser if available,
				-- an Eiffel parser otherwise.
			create an_expat_parser_factory
			if an_expat_parser_factory.is_expat_parser_available then
				xml_parser := an_expat_parser_factory.new_expat_parser
			else
				create {XM_EIFFEL_PARSER} xml_parser.make
			end
			xml_parser.set_string_mode_mixed
				-- The parser will build a tree.
			create tree_pipe.make
			xml_parser.set_callbacks (tree_pipe.start)
			tree_pipe.tree.enable_position_table (xml_parser)
		ensure
			ast_factory_set: ast_factory = a_factory
			error_handler_set: error_handler = an_error_handler
		end

feature -- Parsing

	parse_file (a_file: KI_CHARACTER_INPUT_STREAM) is
			-- Parse Xace file `a_file'.
		require
			a_file_not_void: a_file /= Void
			a_file_open_read: a_file.is_open_read
		local
			a_root_name: STRING
			a_system: ET_XACE_SYSTEM
			a_library: ET_XACE_LIBRARY
			a_document: XM_DOCUMENT
			a_root_element: XM_ELEMENT
			a_position_table: XM_POSITION_TABLE
		do
			xml_parser.parse_from_stream (a_file)
			if xml_parser.is_correct then
				if not tree_pipe.error.has_error then
					a_document := tree_pipe.document
					a_root_element := a_document.root_element
					a_root_name := a_root_element.name
					a_position_table := tree_pipe.tree.last_position_table
					if STRING_.same_string (a_root_name, uc_system) then
						xml_validator.validate_system_doc (a_document, a_position_table)
						if not xml_validator.has_error then
							xml_preprocessor.preprocess_element (a_root_element, a_position_table)
							a_system := new_system (a_root_element, a_position_table)
							parsed_libraries.wipe_out
						end
					elseif
						STRING_.same_string (a_root_name, uc_library) or
						STRING_.same_string (a_root_name, uc_cluster)
					then
						xml_validator.validate_library_doc (a_document, a_position_table)
						if not xml_validator.has_error then
							xml_preprocessor.preprocess_element (a_root_element, a_position_table)
							a_library := new_library (a_root_element, a_position_table)
							parsed_libraries.wipe_out
						end
					else
						error_handler.report_not_xace_file_error (a_file.name)
					end
				else
					error_handler.report_parser_error (tree_pipe.last_error)
				end
			else
				error_handler.report_parser_error (xml_parser.last_error_extended_description)
			end
		end

feature -- Access

	library_parser: ET_XACE_LIBRARY_PARSER
			-- Library Parser

	parsed_libraries: DS_HASH_TABLE [ET_XACE_LIBRARY, STRING]
			-- Already parsed Xace libraries, indexed by filenames

feature -- Setting

	set_parsed_libraries (a_libraries: like parsed_libraries) is
			-- Set `parsed_libraries' to `a_libraries'.
		require
			a_libraries_not_void: a_libraries /= Void
			no_void_library: not a_libraries.has_item (Void)
		do
			parsed_libraries := a_libraries
		ensure
			parsed_libraries_set: parsed_libraries = a_libraries
		end

feature {NONE} -- Implementation

	xml_parser: XM_PARSER
			-- XML parser

	tree_pipe: XM_TREE_CALLBACKS_PIPE
			-- Tree generating callbacks

	xml_validator: ET_XACE_VALIDATOR
			-- XML validator

	xml_preprocessor: ET_XACE_PREPROCESSOR
			-- XML preprocessor

invariant

	xml_parser_not_void: xml_parser /= Void
	tree_pipe_not_void: tree_pipe /= Void
	position_table_enabled: tree_pipe.tree.is_position_table_enabled
	xml_validator_not_void: xml_validator /= Void
	xml_preprocessor_not_void: xml_preprocessor /= Void

end
