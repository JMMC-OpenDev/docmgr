xquery version "3.0";

declare namespace ads="http://ads.harvard.edu/schema/abs/1.1/abstracts";

(:  
doc("http://jmmc.fr/bibdb/xml")//bibcode

let $cache := doc("/db/apps/docmgr-data/data/ads/cache.xml")

xmldb:store("/db/apps/docmgr-data/data/ads/","ca.xml", <a/>)

let $cache := doc("/db/apps/docmgr-data/data/ads/cache.xml")
return reverse(count($cache//a))

let $cache := doc("/db/apps/docmgr-data/data/ads/cache.xml")
return $cache//ads:link[@type="PREPRINT"]/ads:url

let $cache := doc("/db/apps/docmgr-data/data/ads/cache.xml")
return count($cache//ads:link[@type="ARTICLE" and @access="open"]/ads:url)

doc("/db/apps/docmgr-data/data/ads/cache.xml")//a
count(doc("http://apps.jmmc.fr/exist/rest/db/apps/docmgr-data/data/olbin")/*/*/*)
reverse(doc("/db/apps/docmgr-data/data/ads/cache.xml")//e)
:)

let $cache := doc("/db/apps/docmgr-data/data/ads/cache.xml")
let $records := $cache//ads:record[.//ads:link[@type="ARTICLE" and @access="open"]]
let $l := for $r in $records
    let $b := $r//ads:bibcode
    let $url := $r//ads:link[@type="ARTICLE" and @access="open"]/ads:url
    let $available := util:binary-doc-available("/db/apps/docmgr-data/dtarea/olbin/"||$b||".pdf")
    return if($available) then () else $b
return (string-join($l,  ";"), count($l))