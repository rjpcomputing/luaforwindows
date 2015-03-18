require "oil"
oil.main(function()
	local orb = oil.init()
	
	orb:loadidl[[
		typedef sequence<string> StringSequence;
		
		exception CompileError {
			string message;
			string code;
		};
		
		interface ComponentAdaptor {
			void apply_change(
				in StringSequence triggers,
				in string state_adaptation_code,
				in string code_adaptation_code,
				in string new_interface_def
			) raises (CompileError);
		};
	]]
	
	Adaptor = orb:newproxy(oil.readfrom("adaptor.ior"))
	Adaptor:apply_change({"submit"}, -- triggering operations
		[[
			local emailset = {}
			for _, email in ipairs(self.emails) do
				local count = emailset[email] or 0
				emailset[email] = count + 1
			end
			self.emails = emailset
		]],
		[[
			function Collector:submit(paper)
				self:request_mail()
				for email in pairs(self.emails) do
					self:send_to(email, "New paper submitted titled "..paper.title)
				end
				local sum = 0
				for _, author in ipairs(paper.authors) do
					local count = self.emails[author.email] or 0
					self.emails[author.email] = count + 1
					sum = sum + count
				end
				return sum
			end
		]],
		[[
			struct Author {
				string name;
				string email;
			};
			typedef sequence<Author> AuthorSeq;
			struct Paper {
				string title;
				AuthorSeq authors;
			};
			interface Collector {
				long submit(in Paper paper);
			};
		]]
	)
	
end)