xquery version "3.0";

(:import module namespace app="http://apps.jmmc.fr/exist/apps/docmgr/templates" at "modules/app.xql";:)

import module namespace config="http://apps.jmmc.fr/exist/apps/docmgr/config" at "modules/config.xqm";


declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

declare variable $olbindoc := doc("http://jmmc.fr/bibdb/xml");


let $doc := $config:docmgr-tags-doc//e
(:let $bibcodes := distinct-values($doc//bibcode):)
(::)
(:let $data := for $b_by_date in $bibcodes group by $date:=substring($b_by_date,1,4) order by $date         :)
(:    return for $b in $b_by_date return :)
(:        <pub>:)
(:            <id>{$b}</id>:)
(:            <date>{$date}</date>:)
(:            { for $tag in $doc[bibcode=$b]/tag return <tags>{data($tag)}</tags> }:)
(:        </pub>:)

let $data := for $e in $olbindoc//e 
    let $b := data($e/bibcode)
    let $date := substring($b,1,4)
    order by $e/pubdate
    return
        <pub>
            <id>{$b}</id>
            <date>{$date}</date>
            {$e/pubdate}
            <cite>{ if ($doc[bibcode=$b]/tag or $e/tag[.="JMMC"])  then "true" else "false" }</cite>
            { for $tag in $doc[bibcode=$b]/tag return <tags>{data($tag)}</tags> }
        </pub>


return <pubs>{$data}</pubs>
