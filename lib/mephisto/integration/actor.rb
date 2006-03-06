module Mephisto
  module Integration
    module Actor
      def read(record = nil)
        url = case record
          when Article then record.full_permalink
          when Section then record.to_url * '/'
          else record.to_s
        end
        get url
        assert_equal 200, status
      end

      def syndicate(section)
        get "/feed/#{section.to_feed_url * '/'}"
        assert_equal 200, status
      end

      def revise(article, contents)
        post "/admin/articles/update/#{article.id}", to_article_params(article, contents.is_a?(Hash) ? contents : {:body => contents})
        assert_redirected_to "/admin/articles/index"
      end

      def create(params)
        post '/admin/articles/create', to_article_params(params)
        assert_redirected_to "/admin/articles"
      end

      private
        def to_article_params(*args)
          options = args.pop
          article = args.first
          if article
            options[:published_at] ||= article.published_at
            options[:sections]     ||= article.sections
            [:title, :excerpt, :body].each { |key| options[key] ||= article.send(key) }
          end

          params = [:title, :excerpt, :body].inject({}) { |params, key| params.merge "article[#{key}]" => options[key] }
          params['article_published'] = options[:published_at] ? '1' : '0'
          add_published_at! params, options[:published_at] if options[:published_at].is_a?(Time)
          params = params.keys.inject([]) { |all, k| params[k] ? all << "#{k}=#{CGI::escape params[k]}" : all } # change to an array so we can add multiple sections
          add_section_ids! params, options[:sections]
          params * '&'
        end

        def add_published_at!(params, date)
          params.update to_date_params(:article, :published_at, date)
        end

        def add_section_ids!(params, sections)
          (sections || []).each { |s| params << "article[section_ids][]=#{s.id}" }
        end

        def to_date_params(object, method, date)
          {
            "#{object}[#{method}(1i)]" => date.year.to_s,
            "#{object}[#{method}(2i)]" => date.month.to_s,
            "#{object}[#{method}(3i)]" => date.day.to_s,
            "#{object}[#{method}(4i)]" => date.hour.to_s,
            "#{object}[#{method}(5i)]" => date.min.to_s
          }
        end
    end
  end
end