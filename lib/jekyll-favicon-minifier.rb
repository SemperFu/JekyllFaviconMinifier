module Jekyll
  module JekyllFaviconMinifier
    class StaticFile < Jekyll::StaticFile
      include Compressor # From jekyll-minifier
      
      # Logic from jekyll-favicon
      include Convertible
      include Jekyll::Favicon::StaticFile::Mutable
      #include Mutable

      # Overriding the copy_file method to integrate both plugins
      def copy_file(*args)
        dest_path = args.last
      
        # If called with one argument, it's from jekyll-favicon
        if args.size == 1
          case @extname
          when ".svg"
            super(dest_path)
          when ".ico", ".png"
            Utils.convert path, dest_path, convert
          else
            Jekyll.logger.warn "Jekyll::Favicon: Can't generate " \
                               " #{dest_path}. Extension not supported."
          end
        # If called with two arguments, it's likely from jekyll-minifier or other plugins
        elsif args.size == 2
          source_path = args.first
          FileUtils.mkdir_p(File.dirname(dest_path))
          FileUtils.cp(source_path, dest_path)
        end
      end

      # Overriding the write method to integrate jekyll-minifier's logic
      def write(dest)
        dest_path = destination(dest)

        return false if File.exist?(dest_path) and !modified?
        self.class.mtimes[path] = mtime

        if exclude?(dest, dest_path)
          copy_file(path, dest_path)
        else
          case File.extname(dest_path)
          when '.js'
            if dest_path.end_with?('.min.js')
              copy_file(path, dest_path)
            else
              output_js(dest_path, File.read(path))
            end
          when '.json'
            output_json(dest_path, File.read(path))
          when '.css'
            if dest_path.end_with?('.min.css')
              copy_file(path, dest_path)
            else
              output_css(dest_path, File.read(path))
            end
          when '.xml'
            output_html(dest_path, File.read(path))
          else
            copy_file(path, dest_path)
          end
        end
        true
      end
    end
  end
end
