# Wiki Extensions plugin for Redmine
# Copyright (C) 2009-2013  Haruyuki Iida
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require_dependency 'wiki_controller'

class WikiController
  after_action :wiki_extensions_save_tags, :only => [:edit, :update]
end

module WikiExtensions
  module Patches
    module WikiControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :respond_to_without_wiki_extensions, :respond_to
          alias_method :respond_to, :respond_to_with_wiki_extensions

          alias_method :render_without_wiki_extensions, :render
          alias_method :render, :render_with_wiki_extensions
        end
      end
    end

    module InstanceMethods
      def render_with_wiki_extensions(args = nil)
        if args and @project and WikiExtensionsUtil.is_enabled?(@project) and @content
          if (args.class == Hash and args[:partial] == 'common/preview')
            WikiExtensionsFootnote.preview_page.wiki_extension_data[:footnotes] = []
          end
        end

        render_without_wiki_extensions(args)
      end

      def respond_to_with_wiki_extensions(&block)
        if @project and WikiExtensionsUtil.is_enabled?(@project) and @content
          if (@_action_name == 'show')
            wiki_extensions_include_header
            wiki_extensions_add_fnlist
            wiki_extensions_include_footer
          end
        end

        respond_to_without_wiki_extensions(&block)
      end

      def wiki_extensions_get_current_page
        @page
      end

      private

      def wiki_extensions_save_tags
        return true if request.get?

        extension = params[:extension]
        return true unless extension

        tags = extension[:tags]

        @page.set_tags(tags)
      end

      def wiki_extensions_add_fnlist
        text = @content.text
        text << "\n\n{{fnlist}}\n"
      end

      def wiki_extensions_include_header
        return if @page.title == 'Header' || @page.title == 'Footer'
        header = @wiki.find_page('Header')
        return unless header
        text = "\n"
        text << '<div id="wiki_extentions_header">'
        text << "\n\n"
        text << header.content.text
        text << "\n\n</div>"
        text << "\n\n"
        text << @content.text
        @content.text = text

      end

      def wiki_extensions_include_footer
        return if @page.title == 'Footer' || @page.title == 'Header'
        footer = @wiki.find_page('Footer')
        return unless footer
        text = @content.text
        text << "\n"
        text << '<div id="wiki_extentions_footer">'
        text << "\n\n"
        text << footer.content.text
        text << "\n\n</div>"

      end
    end
  end
end

WikiController.send(:include, WikiExtensions::Patches::WikiControllerPatch) unless WikiController.included_modules.include?(WikiExtensions::Patches::WikiControllerPatch)
