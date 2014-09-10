xquery version "3.0";

declare namespace ads="http://ads.harvard.edu/schema/abs/1.1/abstracts";

(: 
let $s:=xmldb:store("/db/apps/docmgr/data", "bibdb.xml", doc("http://jmmc.fr/bibdb/xml"))
return ()
 :)
let $bibdb := doc("/db/apps/docmgr/data/bibdb.xml")
let $links := for $e at $pos in $bibdb//e[not(ads:link)]
    let $adsRecord := doc(concat("http://adsabs.harvard.edu/abs/", $e/bibcode, "&amp;data_type=XML"))
    return ($pos,update insert ($adsRecord//ads:link, if($adsRecord//ads:record/@refereed)then <refereed/> else(),<date>{current-dateTime()}</date>) into $e  )

return $links