module MetaRuby
    module GUI
        # Widget that allows to display a list of exceptions
        class ExceptionView < Qt::WebView
            RESSOURCES_DIR = File.expand_path('html', File.dirname(__FILE__))

            attr_reader :displayed_exceptions

            def initialize(parent = nil)
                super
                @displayed_exceptions = []
                self.focus_policy = Qt::NoFocus
            end

            def push(exception, reason = nil)
                @displayed_exceptions << [exception, reason]
                update_html
            end

            def clear
                @displayed_exceptions.clear
                update_html
            end

            TEMPLATE = <<-EOD
            <html>
            <link rel="stylesheet" href="file://#{File.join(RESSOURCES_DIR, 'exception_view.css')}" type="text/css" />
            <script type="text/javascript" src="file://#{File.join(RESSOURCES_DIR, 'jquery.min.js')}"></script>
            </html>
            <script type="text/javascript">
            $(document).ready(function () {
                $("tr.backtrace").hide()
                $("a.backtrace_toggle_filtered").click(function (event) {
                        var eventId = $(this).attr("id");
                        $("#backtrace_full_" + eventId).hide();
                        $("#backtrace_filtered_" + eventId).toggle();
                        event.preventDefault();
                        });
                $("a.backtrace_toggle_full").click(function (event) {
                        var eventId = $(this).attr("id");
                        $("#backtrace_full_" + eventId).toggle();
                        $("#backtrace_filtered_" + eventId).hide();
                        event.preventDefault();
                        });
            });
            </script>
            <body>
            <table class="exception_list">
            <%= displayed_exceptions.enum_for(:each_with_index).map { |(e, reason), idx| render_exception(e, reason, idx) }.join("\\n") %>
            </table>
            </body>
            EOD

            def update_html
                self.html = ERB.new(TEMPLATE).result(binding)
            end

            class BacktraceParser
                def initialize(backtrace)
                    @backtrace = backtrace
                end

                def parse
                    call_stack(0)
                end

                def pp_call_stack(level)
                    @backtrace[level..-1]
                end
            end

            EXCEPTION_TEMPLATE = <<-EOF
            <tr class="message">
                <td id="<%= idx %>"><%= escape_html(reason) if reason %><pre><%= message.join("\n") %></pre>(<%= e.class %>)
                <span class="backtrace_links">
                    (show: <a class="backtrace_toggle_filtered" id="<%= idx %>">filtered backtrace</a>,
                           <a class=\"backtrace_toggle_full\" id="<%= idx %>">full backtrace</a>)
                </span>
                </td>
            </tr>
            <tr class="backtrace_summary">
                <td>from <%= escape_html(origin_file) %>:<%= origin_line %>:in <%= escape_html(origin_method.to_s) %></td>
            </tr>
            <tr class="backtrace" id="backtrace_filtered_<%= idx %>">
                <td><%= render_backtrace(filtered_backtrace) %></td>
            </tr>
            <tr class="backtrace" id="backtrace_full_<%= idx %>">
                <td><%= render_backtrace(full_backtrace) %></td>
            </tr>
            EOF

            def render_exception(e, reason, idx)
                message = PP.pp(e, "").split("\n").map { |line| escape_html(line) }
                filtered_backtrace = BacktraceParser.new(Roby.filter_backtrace(e.backtrace, :force => true)).parse
                origin_file, origin_line, origin_method = filtered_backtrace.
                    find { |file, _| Roby.app.app_file?(file) } || filtered_backtrace.first
                full_backtrace = BacktraceParser.new(e.backtrace).parse
                ERB.new(EXCEPTION_TEMPLATE).result(binding)
            end

            def render_backtrace(backtrace)
                result = []
                backtrace.each do |file, line, method|
                    if Roby.app.app_file?(file)
                        result << "  <span class=\"app_file\">#{escape_html(file)}:#{line}:in #{escape_html(method.to_s)}</span><br/>"
                    else
                        result << "  #{escape_html(file)}:#{line}:in #{escape_html(method.to_s)}<br/>"
                    end
                end
                result.join("\n")
            end

            def escape_html(l)
                l.gsub('<', '&lt;').gsub('>', '&gt;')
            end

            def exceptions=(list)
                @displayed_exceptions = list.dup
                update_html
            end
        end
    end
end

