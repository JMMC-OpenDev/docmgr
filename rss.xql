xquery version "3.0";

import module namespace app="http://apps.jmmc.fr/exist/apps/docmgr/templates" at "modules/app.xql";

import module namespace config="http://apps.jmmc.fr/exist/apps/docmgr/config" at "modules/config.xqm";
 
declare option exist:serialize "method=xml media-type=application/rss+xml";

(: TODO move back to 20 when it will be in production :)
let $max:=number(request:get-parameter("max", 50))

return
    <rss version="2.0">
        <channel>
            <title>RSS - {config:app-title(<e/>,map {})} </title>
            <link></link>
            <description></description>
            {
                app:rssItems($max)
            }
        </channel>
    </rss>