indexing

	description:

		"Pure XPath implementation of the node-kind-test pattern"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2004, Colin Adams and others"
	license: "Eiffel Forum License v2 (see forum.txt)"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_NODE_KIND_TEST

inherit

	XM_XPATH_NODE_TEST
		redefine
			item_type
		end

creation

	make

feature {NONE} -- Initialization

	make (node_type: INTEGER) is
			-- Establish invariant
		require
			valid_node_type: is_node_type (node_type)
		do
			kind := node_type
		ensure
			kind_set: kind = node_type
		end

feature -- Access

	item_type: INTEGER is
			-- Determine the types of nodes to which this pattern applies;
			-- Used for optimisation;
			-- For patterns that match nodes of several types, return Any_node
		do
			Result := kind
		end

feature -- Status report

	allows_text_nodes: BOOLEAN is
			-- Does this node test allow text nodes?
		do
			Result := kind = Text_node
		end

feature -- Matching

	matches_node (a_node_kind: INTEGER; a_fingerprint: INTEGER; a_node_type: INTEGER): BOOLEAN is
			-- Is this node test satisfied by a given node?
		do
			Result := kind = a_node_kind
		end	

feature {NONE} -- Implementation

	kind: INTEGER
			--  The kind of node alllowed by this test

invariant
	valid_node_type: is_node_type (kind)

end