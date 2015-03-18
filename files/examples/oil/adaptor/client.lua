require "oil"
oil.main(function()
	orb = oil.init()
	orb:loadidl[[
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
			void submit(in Paper paper);
		};
	]]
	
	local c1 = orb:newproxy(oil.readfrom("c1.ior"))
	local c2 = orb:newproxy(oil.readfrom("c2.ior"))
	local c3 = orb:newproxy(oil.readfrom("c3.ior"))
	
	Titles = {
		"Guidelines for Constructing Consumption Aggregates for Welfare Analysis",
		"Social Assistance in Albania: Decentralization and Targeted Transfers",
		"Poverty Lines in Theory and Practice",
		"The Role of the Private Sector in Education in Vietnam: Evidence from the Vietnam Living Standards Survey",
		"Chronic Illness and Retirement in Jamaica",
		"Model Living Standards Measurement Study Survey Questionnaire for Countries of the Former Soviet Union",
		"Poverty Comparisons and Household Survey Design",
		"How Does Schooling of Mothers Improve Child Health? Evidence from Morocco",
		"Unconditional Demand for Health Care in Côte d'Ivoire: Does Selection on Health Status Matter?",
		"A Manual for Planning and Implementing the LSMS Survey",
		"The Contribution of Income Components to Income Inequality in South Africa: A Decomposable Gini Analysis",
		"Constructing an Indicator of Consumption for the Analysis of Poverty: Principles and Illustrations with Reference to Ecuador",
		"The Demand for Medical Care: Evidence from Urban Areas in Bolivia",
		"Comparaisons de la Pauvreté : Concepts et méthodes",
		"Infrastructure and Poverty in Viet Nam",
		"A Guide to Living Standards Measurement Study Surveys and Their Data Series",
		"Women's Schooling, the Selectivity of Fertility, and Child Mortality in Sub-Saharan Africa",
		"Proxy Means Tests for Targeting Social Programs",
		"Who Is Most Vulnerable to Macroeconomic Shocks? Hypotheses Tests Using Panel Data from Peru",
		"Health Care in Jamaica: Quality, Outcomes, and Labor Supply",
		"Changing Patterns of Illiteracy in Morocco, Assessment Methods compared",
		"The Quality and Availability of Family Planning Services and Contraceptive Use in Tanzania",
		"Sector Participation Decisions in Labor Supply Models",
		"The Tradeoff Between Number of Children and Child Schooling: Evidence from Côte d'Ivoire and Ghana (abstract available in French)",
		"Contraceptive Use in Ghana: The Role of Service Availability, Quality, and Price",
	}
	Authors = {
		{ name ="Afvpmj Xtewsnhacj Dz"       , email ="daaj@opperl.jbp.uu"        },
		{ name ="Nwsy Ydmgwfu Vzpkgh"        , email ="ajcrbax@hpr.vsm.ft"        },
		{ name ="Mytcp Kpojdflun Zierm"      , email ="s@dydxsh.lbz.rd"           },
		{ name ="Wpeevmen Thorts Mj"         , email ="anrlcyx@imjwil.hzh.to"     },
		{ name ="Fvknxazo Bfvqrfv Dt"        , email ="yhi@tv.spt.gd"             },
		{ name ="Au Wdoa Ctro"               , email ="l@shl.gpn.qe"              },
		{ name ="Nsyeiezlz Cclybxhf Tfqp"    , email ="mpqw@qsojetoxg.eps.pj"     },
		{ name ="Mt Prudowxp Sr"             , email ="iohecwwt@ic.bqv.ol"        },
		{ name ="Kmnd Iivywshyd Bnpyb"       , email ="ricnfhxo@cmjmunj.rnp.ka"   },
		{ name ="Sq Wtmjuo Jqejdt"           , email ="paibqdww@swadsq.fbe.qi"    },
		{ name ="Iruu Nuxdqkgd Wl"           , email ="hofic@dhuxutpjw.fwf.go"    },
		{ name ="Zc Ncgxgd Dcbbix"           , email ="lyvn@skganykgp.gry.lx"     },
		{ name ="Apuodfjak Cwbvrrun Rr"      , email ="uawqsc@ybhdzq.hxj.sf"      },
		{ name ="Enx Clcuezuwfla Tk"         , email ="zbg@gd.qxy.fu"             },
		{ name ="Qxlxrdq Oyopng Kau"         , email ="bk@bfeqlp.slr.kv"          },
		{ name ="Pyw Kexolqsbhgk Xsxkk"      , email ="ikojtttt@fh.rxj.nc"        },
		{ name ="Xnr Lccbajhs Dbr"           , email ="fsqroc@bzmzsn.rsj.kb"      },
		{ name ="Vbi Uima Lptk"              , email ="vyq@bowkhhapka.alw.yk"     },
		{ name ="Svwppc Uppovr Ig"           , email ="guj@dsqxenxuz.fxu.yw"      },
		{ name ="Xeqggtu Emcuwdhom Ts"       , email ="aqrebhrv@jugqgf.zha.td"    },
		{ name ="Bj Qkkco Srw"               , email ="obmgl@mcosuwwhw.qtv.tw"    },
		{ name ="Xnlcjvlea Rbckruedb Iz"     , email ="bxqlag@ruav.dqo.zm"        },
		{ name ="Fuim Pzt Dszu"              , email ="qyrhoh@sgomyr.tql.ut"      },
		{ name ="Zqx Pnmlxyegfsy Qq"         , email ="o@lbzdpb.eri.iq"           },
		{ name ="Kfrem Nlaijdvtxq Qtty"      , email ="jcxv@cwtbk.ybe.fd"         },
		{ name ="Pq Ptxrhvjz Uek"            , email ="pf@ejhdfbutwa.llu.lm"      },
		{ name ="Toc Xwbmqttgxu Fbnu"        , email ="atoxwu@kmbq.att.fe"        },
		{ name ="Baisulz Qmwc Cd"            , email ="ijvbvgxg@ffw.wxv.pb"       },
		{ name ="Ejl Eqoxnszzwv Dhe"         , email ="tsaqvtvd@jqxxaula.fke.xn"  },
		{ name ="Gxfaufou Wozwq Fjjaok"      , email ="i@fydwxlfqo.qla.wd"        },
		{ name ="Groy Pkvtdnaat Imtbqa"      , email ="znsgvq@gvltja.mqk.ja"      },
		{ name ="Hwlyjn Awlsipmobjg Yzppbk"  , email ="mcw@uypf.how.gh"           },
		{ name ="Sgelxoaz Bgedgmyb Chn"      , email ="kyph@kyovu.upw.iy"         },
		{ name ="Gsdumeabl Waf Vurhu"        , email ="vgmabajs@ehetd.bnj.ue"     },
		{ name ="Xae Vojo Ryycdo"            , email ="xbwvkor@hyzsp.hdf.pm"      },
		{ name ="Jmr Yzgngxmi Nije"          , email ="fxt@qrhtbswib.mav.qo"      },
		{ name ="Puqstw Eualbn Hg"           , email ="nqbjywig@bze.bfh.uq"       },
		{ name ="Cdfo Ecltibhs Wwcu"         , email ="qqppfzgb@gku.hxj.sf"       },
		{ name ="Bjjrzf Xyrfh Jhfc"          , email ="s@rvampyhpt.wxv.ph"        },
		{ name ="Uor Kckargefewt Bbyc"       , email ="zowkk@rvyha.qbr.ky"        },
		{ name ="Pki Qackhivwif Ozlj"        , email ="kpwi@ynkp.ucd.fc"          },
		{ name ="Iqicp Dvlz Fn"              , email ="aou@zj.xnf.hm"             },
		{ name ="Itvkl Scctwqjmc Ki"         , email ="fieiehfe@bnzv.lxe.mm"      },
		{ name ="Syh Hvquaghywn Sxm"         , email ="v@h.jqn.ld"                },
		{ name ="Za Xteclr Nvhmwd"           , email ="nfbffffy@thruxy.vgc.bx"    },
		{ name ="Djyjirxjl Rmnu Umvoh"       , email ="bxt@hfib.wgk.dw"           },
		{ name ="Pfltlque Isfwbtadcoo Nch"   , email ="k@gv.ngz.xd"               },
		{ name ="Hmhinvn Bocnysmlxo Jrdnch"  , email ="ujwtm@lpjq.omv.ea"         },
		{ name ="Cf Gsldow Uyi"              , email ="pa@nkagxpdanx.qfk.zc"      },
		{ name ="Kiiqgh Nmirlpkxdr Dcc"      , email ="vmlqkq@v.jwn.zk"           },
		{ name ="Sjvwbtj Guhoedtkhe Oif"     , email ="srqbiy@hejh.ygg.qt"        },
		{ name ="Psis Aqdsjnwpm Aojot"       , email ="a@thuvsh.okc.kc"           },
		{ name ="Rrr Ttogcgtzmf Ujmzj"       , email ="fqodylqb@tcqfgtz.txo.xw"   },
		{ name ="Qtdtdkp Sxbkpmltpi Ptc"     , email ="z@k.ckl.hl"                },
		{ name ="Fqxw Lgztis Pxrgc"          , email ="soanl@xsgcgmpbkd.ztb.ar"   },
		{ name ="Ytdrprz Bwqxodxogeq Vwlzr"  , email ="bvtzvi@fh.yvg.fw"          },
		{ name ="Lyt Koqyt Toz"              , email ="ilqsmr@cbd.leq.wg"         },
		{ name ="Vxcgms Sjm Yl"              , email ="n@uvto.bez.lq"             },
		{ name ="Svxmmstjt Havtl Fg"         , email ="tigmto@szkh.xpp.ju"        },
		{ name ="Vlcqzrme Owhz Vikr"         , email ="xhtnyxqb@hug.hjx.vg"       },
		{ name ="Iyg Ycpfjeuxib Toojc"       , email ="u@i.idn.it"                },
		{ name ="Pyrspb Hu Zhmd"             , email ="eojnr@sqdysbfm.dzl.up"     },
		{ name ="Uvhzwi Ezz Pb"              , email ="klt@pwoxffeli.fvu.wk"      },
		{ name ="Lbuhnfrhe Wvxpel Rzzncb"    , email ="wppph@kwdzbkij.aif.um"     },
		{ name ="Bkolsoppf Jxovuyufq Nvsrqk" , email ="zngprqyo@nfw.eds.ro"       },
		{ name ="Qzpnnbvxo Gy Vd"            , email ="jtbiabj@f.otj.lc"          },
		{ name ="Viypo Wgigqrr Tnek"         , email ="zxab@k.iyv.om"             },
		{ name ="Kncwktzfa Mji Yy"           , email ="uutpbbo@dhtijnx.yyw.oy"    },
		{ name ="Rzly Pesbin Fe"             , email ="hwoja@ho.atb.xu"           },
		{ name ="Fluwx Ogpqsyod Jutyuc"      , email ="a@lfqfitqyeq.ekb.kt"       },
		{ name ="Trkmqche Gaziznbo Kk"       , email ="hf@g.pwi.px"               },
		{ name ="Tu Qc Nlar"                 , email ="kbivcxps@pb.hoq.qv"        },
		{ name ="Ooyibrf Ugwmotatmh Lcyaf"   , email ="oiaxshu@f.goa.dn"          },
		{ name ="Jwake Tjejm Ios"            , email ="jfze@lfvx.sls.hm"          },
		{ name ="Eikal Haowt Qrzm"           , email ="rqtxokju@hb.jil.bl"        },
		{ name ="Mu Dvkfwtic Bnk"            , email ="mxlfo@opfqluionr.zdh.aa"   },
		{ name ="Keq Atwjmokuegn Iltmb"      , email ="ylqfg@zkfevmra.iez.zn"     },
		{ name ="Wo Wkpsrhwq Lwode"          , email ="qxj@qafox.vfu.qg"          },
		{ name ="Fnt Vu Za"                  , email ="rjkucyj@vufquqtmk.tnt.hp"  },
		{ name ="Xuykw Oyunnbqlv Holy"       , email ="kjqfuf@odaj.gjm.xu"        },
		{ name ="Lsqjb Edd Ku"               , email ="mndvfny@wnngltbpb.ber.fy"  },
		{ name ="Wojvf Bewenwmgb Ccyz"       , email ="vb@dvzbafqs.rkt.uk"        },
		{ name ="Irdpxg Vvoelwr Sq"          , email ="jqtyx@tujju.adi.ii"        },
		{ name ="Rsmjvbuzs Brzf Jg"          , email ="ly@sfoktb.uzo.jc"          },
		{ name ="Onsoike Bhc Rqqva"          , email ="rzeewzo@wev.ell.jv"        },
		{ name ="Klfp Fuxolvxa Rrgdal"       , email ="bmvsbil@frcineqcm.ocw.xm"  },
		{ name ="Jjcqqviy Ihfhlkhog Wbwk"    , email ="fty@tzlxqevf.kts.pz"       },
		{ name ="Aplljppka Cgcbkfaw Goagv"   , email ="cssbcxy@mttd.snl.gv"       },
		{ name ="Ctvvho Qqzsx Zapvi"         , email ="nlaoom@ihsjiozxfg.hwd.xg"  },
		{ name ="Wgylta Lireelexz Vp"        , email ="kwchgriz@qosohw.zbw.em"    },
		{ name ="Erqvwqw Zabwwrtoogq Zvz"    , email ="msuv@addcczjtn.des.wn"     },
		{ name ="Oujg Udthojds Dvuegq"       , email ="o@xvtp.ics.ui"             },
		{ name ="Sjzqamd Ivnerjb Cp"         , email ="euncb@fwzxact.fbx.vm"      },
		{ name ="Iqwh Qoiikne Jk"            , email ="v@dat.urz.vv"              },
		{ name ="Cujbaspwz Ivaqapacjv Bfbilg", email ="bkhqtxvn@pkfft.sje.zi"     },
		{ name ="Pfmdh Dtoaoii Yff"          , email ="bjikdulu@tgildrtph.gnw.se" },
		{ name ="Alpj Hjikywnv Vsp"          , email ="guoe@ihzby.pxa.nl"         },
		{ name ="Oub Zvpja Kvt"              , email ="rlx@rvjb.ktl.id"           },
		{ name ="Idksfgrnl Wmkmrnoe Eqgsok"  , email ="iwvru@wazuj.yaw.ch"        },
		{ name ="Gg Iyxzo Kmnd"              , email ="zsjhb@zcwjjzz.xwx.pg"      },
	}                        
           
	function getauthors()
		local authors = {}
		for i=1, math.random(6) do
			table.insert(authors, Authors[math.random(table.getn(Authors))])
		end      
		return authors
	end
                         
	while true do            
		c1:submit{             
			title = Titles[math.random(table.getn(Titles))];
			authors = getauthors();
		}
		oil.sleep(1)
		c2:submit{             
			title = Titles[math.random(table.getn(Titles))];
			authors = getauthors();
		}
		oil.sleep(1)
		c3:submit{             
			title = Titles[math.random(table.getn(Titles))];
			authors = getauthors();
		}
		oil.sleep(1)
	end
	
end)