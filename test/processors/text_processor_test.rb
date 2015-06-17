require 'test_helper'

class TextProcessorTest < ActiveSupport::TestCase
  let(:audio_monster) do
    Minitest::Mock.new
  end

  let(:processor) do
    TextProcessor.new(logger: Logger.new('/dev/null')).tap do |p|
      p.audio_monster = audio_monster if travis?
    end
  end

  it 'defines supported tasks' do
    TextProcessor.supported_tasks.first.must_equal 'analyze'
  end

  describe 'copy_file' do

    let(:msg) {
      {
        task: {
          id: 'guid1',
          task_type: 'analyze',
          label: 'sherlock',
          job: { id: 'guid1', job_type: 'text', status: 'created', original: "file://#{in_file('test.txt')}" },
          options: {},
          result: 'file:///test/test_analysis.json'
        }
      }.with_indifferent_access
    }

    before {
      WebMock.disable_net_connect!
    }

    after {
      WebMock.allow_net_connect!
    }

    it 'should analyze file' do

      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String, false])
        audio_monster.expect(:info_for, { format: 'text' }, [String])
      end
      stub_request(:post, "https://api.thomsonreuters.com/permid/calais").
        with(headers: {'Accept'=>'application/json;charset=utf-8', 'Content-Type'=>'text/raw', 'Host'=>'api.thomsonreuters.com:443', 'Outputformat'=>'application/json', 'X-Ag-Access-Token'=>'opencaliasapikey', 'X-Calais-Language'=>'English'}).
        to_return(
          status: 200,
          body: "{\"doc\":{\"info\":{\"calaisRequestID\":\"cd9ead76-b882-ed36-14e0-358e26c4a48e\",\"id\":\"http:\\/\\/id.opencalais.com\\/7aqHU8wDI2uTTCnPcaCsdw\",\"ontology\":\"http:\\/\\/163.231.4.65\\/owlschema\\/8.4\\/onecalais.owl.allmetadata.xml\",\"docId\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\",\"document\":\"<body> Ruby on Rails is a fantastic web framework. It uses MVC, and the ruby programming language invented by Matz\\n <\\/body>\",\"docTitle\":\"\",\"docDate\":\"2015-06-17 21:07:13.739\"},\"meta\":{\"contentType\":\"text\\/html\",\"processingVer\":\"AllMetadata\",\"serverVersion\":\"OneCalais_8.4-RELEASE:366\",\"stagsVer\":\"OneCalais_8.4-RELEASE-b13-2015-04-21_02:28:33\",\"submissionDate\":\"2015-06-17 21:07:13.644\",\"submitterCode\":\"0ca6a864-5659-789d-5f32-f365f695e757\",\"signature\":\"digestalg-1|YZgM6a4MRitEao0+thMks6BNkls=|WX+38itVVvlZiS\\/K0f9lXQNOec1uYrl1dMiRF9ja\\/YVDmbzkb+QSfw==\",\"language\":\"English\"}},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/cat\\/1\":{\"_typeGroup\":\"topics\",\"forenduserdisplay\":\"false\",\"score\":0.949,\"name\":\"Technology_Internet\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/lid\\/DefaultLangId\":{\"_typeGroup\":\"language\",\"language\":\"http:\\/\\/d.opencalais.com\\/lid\\/DefaultLangId\\/English\",\"forenduserdisplay\":\"false\",\"permid\":\"505062\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/1\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/1\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/9eac1ffe-bd0e-382d-8a36-a3fd68ee3368\",\"forenduserdisplay\":\"true\",\"name\":\"Web application frameworks\",\"importance\":\"1\",\"originalValue\":\"Web application frameworks\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/2\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/2\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/9ce34b14-9208-39c1-953a-c6d3718607bb\",\"forenduserdisplay\":\"true\",\"name\":\"Scripting languages\",\"importance\":\"1\",\"originalValue\":\"Scripting languages\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/3\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/3\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/0778a692-08bd-3d6f-998e-bc7f05729153\",\"forenduserdisplay\":\"true\",\"name\":\"Ruby\",\"importance\":\"1\",\"originalValue\":\"Ruby (programming language)\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/4\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/4\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/09786dff-7ffa-3ed8-ac5a-3cfe920689bf\",\"forenduserdisplay\":\"true\",\"name\":\"Ruby on Rails\",\"importance\":\"2\",\"originalValue\":\"Ruby on Rails\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/5\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/5\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/4b5386f7-28c7-39fd-8071-8290dbc329a2\",\"forenduserdisplay\":\"true\",\"name\":\"Web 2.0\",\"importance\":\"2\",\"originalValue\":\"Web 2.0\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/6\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/6\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/9ed92aa4-44ba-3323-a87c-6dc3a2cd10b7\",\"forenduserdisplay\":\"true\",\"name\":\"Rail\",\"importance\":\"2\",\"originalValue\":\"Rail\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/7\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/7\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/aefad89b-0be6-39b2-ad15-9785f4480be4\",\"forenduserdisplay\":\"true\",\"name\":\"Mass assignment vulnerability\",\"importance\":\"2\",\"originalValue\":\"Mass assignment vulnerability\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/8\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/8\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/4cf7cc07-197e-3120-b421-a473bf536036\",\"forenduserdisplay\":\"true\",\"name\":\"Programming language theory\",\"importance\":\"2\",\"originalValue\":\"Programming language theory\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/9\":{\"_typeGroup\":\"socialTag\",\"id\":\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/SocialTag\\/9\",\"socialTag\":\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/3b98d40a-de70-3827-a8ec-67f7e840ba44\",\"forenduserdisplay\":\"true\",\"name\":\"Merb\",\"importance\":\"2\",\"originalValue\":\"Merb\"},\"http:\\/\\/d.opencalais.com\\/dochash-1\\/54069858-1030-3bbf-a8fa-67503b3400d2\\/ComponentVersions\":{\"_typeGroup\":\"versions\",\"version\":[\"Deals Index:201506172022:201506172022\",\"index-refineries:201506140132:201506140132\",\"config-physicalAssets-powerStations:267:267\",\"OA Index:201506112202:201506112202\",\"NextTags:OneCalais_8.4-RELEASE:115\",\"SpanishIM:OneCalais_8.4-RELEASE:200\",\"config-sca-DataPackage:34:34\",\"SECHeaderMetadataIM:OneCalais_8.4-RELEASE:200\",\"com.clearforest.infoext.dial4j.plugins-basistechconfig:OneCalais_8.4-RELEASE:227\",\"People Index:201506171907:201506171907\",\"Collector:OneCalais_8.4-RELEASE:115\",\"config-negativeSignature:267:267\",\"Dial4J:OneCalais_8.4-RELEASE:200\",\"AutocoderRuntimeIM:OneCalais_8.4-RELEASE:200\",\"OA Override:275:275\",\"People Override:267:267\",\"index-vessels:201506131922:201506131922\",\"BrokerResearchIM:OneCalais_8.4-RELEASE:200\",\"config-refineries:267:267\",\"config-cse:271:271\",\"OneCalaisIM:OneCalais_8.4-RELEASE:200\",\"config-vessels:267:267\",\"OneCalais:OneCalais_8.4-RELEASE:366\",\"Housekeeper:OneCalais_8.4-RELEASE:115\",\"WatchDog:OneCalais_8.4-RELEASE:115\",\"config-physicalAssets-mines:267:267\",\"SocialTags Index:201506071134:201506071134\",\"BlackList:275:275\",\"index-ports:201506131317:201506131317\",\"FrenchIM:OneCalais_8.4-RELEASE:200\",\"config-physicalAssets-ports:267:267\",\"config-drugs:267:267\"]},\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/f46e9657-f6d9-358e-8f66-7d7fa7da1857\":{\"_typeGroup\":\"entities\",\"_type\":\"IndustryTerm\",\"forenduserdisplay\":\"false\",\"name\":\"fantastic web framework\",\"_typeReference\":\"http:\\/\\/s.opencalais.com\\/1\\/type\\/em\\/e\\/IndustryTerm\",\"instances\":[{\"detection\":\"[<body> Ruby on Rails is a ]fantastic web framework[. It uses MVC, and the ruby programming language]\",\"prefix\":\"<body> Ruby on Rails is a \",\"exact\":\"fantastic web framework\",\"suffix\":\". It uses MVC, and the ruby programming language\",\"offset\":26,\"length\":23}],\"relevance\":0.2},\"http:\\/\\/d.opencalais.com\\/genericHasher-1\\/1b31f9a1-af99-32eb-90a5-5712a2e2c0f2\":{\"_typeGroup\":\"entities\",\"_type\":\"ProgrammingLanguage\",\"forenduserdisplay\":\"false\",\"name\":\"Ruby on Rails\",\"_typeReference\":\"http:\\/\\/s.opencalais.com\\/1\\/type\\/em\\/e\\/ProgrammingLanguage\",\"instances\":[{\"detection\":\"[<body> ]Ruby on Rails[ is a fantastic web framework. It uses MVC, and]\",\"prefix\":\"<body> \",\"exact\":\"Ruby on Rails\",\"suffix\":\" is a fantastic web framework. It uses MVC, and\",\"offset\":7,\"length\":13}],\"relevance\":0.2}}",
          headers: {
            "Accept-Ranges"       => "bytes",
            "Connection"          => "keep-alive",
            "Content-Length"      => "71879",
            "Content-Type"        => "application/json",
            "Date"                => "Fri, 13 Feb 2015 22:06:17 GMT",
            "Server"              => "Apache-Coyote/1.1",
            "X-Mashery-Responder" => "prod-p-worker-us-east-1d-72.mashery.com"
          }
        )

      stub_request(:post, "http://query.yahooapis.com/v1/public/yql").
        with(headers: {'Accept'=>'application/json;charset=utf-8', 'Content-Type'=>'application/x-www-form-urlencoded', 'Host'=>'query.yahooapis.com:80'}).
        to_return(
          status: 200,
          body: "{\"query\":{\"count\":2,\"created\":\"2015-02-13T22:20:51Z\",\"lang\":\"en-US\",\"results\":{\"yctCategories\":{\"yctCategory\":[{\"score\":\"1\",\"content\":\"Act Of Terror\"},{\"score\":\"0.980535\",\"content\":\"Society & Culture\"},{\"score\":\"0.973282\",\"content\":\"Crime & Justice\"},{\"score\":\"0.925714\",\"content\":\"Unrest, Conflicts & War\"},{\"score\":\"0.799451\",\"content\":\"Politics & Government\"}]},\"entities\":{\"entity\":[{\"score\":\"0.944\",\"text\":{\"end\":\"84\",\"endchar\":\"84\",\"start\":\"70\",\"startchar\":\"70\",\"content\":\"Boston Marathon\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Boston_Marathon\",\"types\":{\"type\":{\"region\":\"us\",\"content\":\"/event/sports\"}}},{\"score\":\"0.944\",\"text\":{\"end\":\"2514\",\"endchar\":\"2514\",\"start\":\"2509\",\"startchar\":\"2509\",\"content\":\"Boston\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Boston_Marathon\",\"types\":{\"type\":[{\"region\":\"us\",\"content\":\"/organization/sports/team\"},{\"region\":\"us\",\"content\":\"/person/music/music_artist\"},{\"region\":\"us\",\"content\":\"/place\"},{\"region\":\"us\",\"content\":\"/place/destination\"}]}},{\"score\":\"0.886\",\"text\":{\"end\":\"1032\",\"endchar\":\"1032\",\"start\":\"1018\",\"startchar\":\"1018\",\"content\":\"pressure cooker\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Pressure_cooking\"},{\"score\":\"0.886\",\"text\":{\"end\":\"3890\",\"endchar\":\"3890\",\"start\":\"3876\",\"startchar\":\"3876\",\"content\":\"pressure cooker\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Pressure_cooking\"},{\"score\":\"0.819\",\"text\":{\"end\":\"1066\",\"endchar\":\"1066\",\"start\":\"1064\",\"startchar\":\"1064\",\"content\":\"FBI\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Federal_Bureau_of_Investigation\",\"types\":{\"type\":[{\"region\":\"us\",\"content\":\"/organization\"},{\"region\":\"us\",\"content\":\"/organization/government\"}]}},{\"score\":\"0.819\",\"text\":{\"end\":\"4468\",\"endchar\":\"4468\",\"start\":\"4466\",\"startchar\":\"4466\",\"content\":\"FBI\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Federal_Bureau_of_Investigation\",\"types\":{\"type\":[{\"region\":\"us\",\"content\":\"/organization\"},{\"region\":\"us\",\"content\":\"/organization/government\"}]}},{\"score\":\"0.816\",\"text\":{\"end\":\"118\",\"endchar\":\"118\",\"start\":\"89\",\"startchar\":\"89\",\"content\":\"federal law enforcement source\"}},{\"score\":\"0.805\",\"text\":{\"end\":\"6470\",\"endchar\":\"6470\",\"start\":\"6456\",\"startchar\":\"6456\",\"content\":\"Boston Marathon\"},\"types\":{\"type\":{\"region\":\"us\",\"content\":\"/event/sports\"}}},{\"score\":\"0.781\",\"text\":{\"end\":\"3529\",\"endchar\":\"3529\",\"start\":\"3516\",\"startchar\":\"3516\",\"content\":\"Martin Richard\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Boston_Marathon_bombings\",\"types\":{\"type\":{\"region\":\"us\",\"content\":\"/person\"}}},{\"score\":\"0.768\",\"text\":{\"end\":\"143\",\"endchar\":\"143\",\"start\":\"131\",\"startchar\":\"131\",\"content\":\"Fran Townsend\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Frances_Townsend\",\"types\":{\"type\":{\"region\":\"us\",\"content\":\"/person\"}}},{\"score\":\"0.744\",\"text\":{\"end\":\"2199\",\"endchar\":\"2199\",\"start\":\"2185\",\"startchar\":\"2185\",\"content\":\"law enforcement\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Law_enforcement\"},{\"score\":\"0.666\",\"text\":{\"end\":\"2073\",\"endchar\":\"2073\",\"start\":\"2045\",\"startchar\":\"2045\",\"content\":\"Boston law enforcement source\"}},{\"score\":\"0.604\",\"text\":{\"end\":\"3897\",\"endchar\":\"3897\",\"start\":\"3892\",\"startchar\":\"3892\",\"content\":\"Boston\"},\"wiki_url\":\"http://en.wikipedia.com/wiki/Boston\",\"types\":{\"type\":[{\"region\":\"us\",\"content\":\"/organization/sports/team\"},{\"region\":\"us\",\"content\":\"/person/music/music_artist\"},{\"region\":\"us\",\"content\":\"/place\"},{\"region\":\"us\",\"content\":\"/place/destination\"}]}}]}}}}",
          headers: {
            "Access-Control-Allow-Origin" => "*",
            "Age"                         => "1",
            "Cache-Control"               => "public, max-age=3599",
            "Connection"                  => "keep-alive",
            "Content-Type"                => "application/json;charset=utf-8",
            "Date"                        => "Fri, 13 Feb 2015 22:20:51 GMT",
            "Server"                      => "ATS",
            "X-Content-Type-Options"      => "nosniff",
            "X-YQL-Host"                  => "engine8.yql.bf1.yahoo.com"
          }
        )


      result_file_path = processor.temp_directory + '/test/test_analysis.json'
      FileUtils.rm(result_file_path) rescue nil
      processor.on_message(msg)

      processor.result_details[:info][:stats].wont_be_nil
      processor.result_details[:info][:stats][:topics].must_be :>, 1

      assert File.exists?(result_file_path)
      f = File.open(result_file_path)
      result = f.read
      json = JSON.parse(result)
      json.must_be :key?, 'language'
      json.must_be :key?, 'topics'
    end
  end
end
