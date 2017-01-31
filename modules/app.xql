xquery version "3.0";

module namespace app="http://apps.jmmc.fr/exist/apps/docmgr/templates";

import module namespace config="http://apps.jmmc.fr/exist/apps/docmgr/config" at "config.xqm";
import module namespace trigger="http://exist-db.org/xquery/trigger" at "cex-trigger.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace util="http://exist-db.org/xquery/util";
    
declare namespace ads="http://ads.harvard.edu/schema/abs/1.1/abstracts";
    
import module namespace jmmc-auth = "http://exist.jmmc.fr/jmmc-resources/auth" at "../../jmmc-resources/content/jmmc-auth.xql";    
import module namespace jmmc-dateutil = "http://exist.jmmc.fr/jmmc-resources/dateutil" at "../../jmmc-resources/content/jmmc-dateutil.xql";    

import module namespace jmmc-ads="http://exist.jmmc.fr/jmmc-resources/ads" at "/db/apps/jmmc-resources/content/jmmc-ads.xql";


declare variable $app:category := ("jmmc","olbin");                

declare variable $app:jmmcdoc := doc("http://www.jmmc.fr/doc/documentation.xml");
declare variable $app:telbib-url := "http://telbib.eso.org/api.php?telescope[]=vlti+visitor&amp;telescope[]=vlti";

declare variable $app:olbindoc := doc("http://jmmc.fr/bibdb/xml");
declare variable $app:arxiv-for-olbin-doc := doc($config:data-root||"/arxiv-for-olbin.xml");

(: declare variable $app:jmmc-info := () :)
declare variable $app:jmmctags := ("Aspro", "Amdlib", "SearchCal", "JSDC", "LITpro", "Wisard","MidiDRS", "PNDRS", 'oidb', 'OIFitsExplorer');

declare variable $app:black-bibcodes := ( '2006ApJ...649..299G', '2007A&amp;A...472..207F', '2007NewAR..51..617B', '2007NewAR..51..623D', '2008AstL...34..753K', '2011A&amp;A...534A.125U', '2011PASA...28..323W', '2012AJ....143..135V', '2013AN....334..912G', '2013ApJ...771..130C', '2013ApJS..208....9P', '2013PASJ...65L...9U', '2013PhDT.......306B', '2014A&amp;A...563A..86L', '2014A&amp;A...566A.124L', '2014A&amp;A...566A..67L', '2014ApJS..211...25C', '2014Icar..231..338M', '2015A&amp;A...573A.138B', '2015A&amp;A...580A..78P', '2015ApJ...798...87M' );

(: todo check if missing bibcodes are refereed papers :)
declare function app:telbib-xmatch($node as node(), $model as map(*)) {
    let $items := doc($app:telbib-url)//item    
    let $olbin-vlti-items := $app:olbindoc//e[tag="VLTI"]
    return 
        ( <table><tr><td><ol>Telbib items not present onto Olbin:
        {
        for $item in $items
            let $bibcode := data($item/bibcode)
            return if($app:olbindoc//bibcode[.=$bibcode]) then ()
                else <li>{let $e := jmmc-ads:get-link($bibcode, ()) return if($bibcode=$app:black-bibcodes) then <strike>{$e}</strike> else $e}</li>                                                             
        }
    </ol></td><td>
     <ol> Olbin items tagget VLTI not present onto <a href="http://telbib.eso.org/index.php?boolany=or&amp;boolins=or&amp;telescope%5B%5D=%22VLTI%22&amp;booltel=or&amp;telescope%5B%5D=VLTI+visitor">Telbib/VLTI</a>:
        {
        for $item in $olbin-vlti-items
            let $bibcode := data($item/bibcode)
            return if($items//bibcode[.=$bibcode]) then ()
                else <li>{jmmc-ads:get-link($bibcode, ())} / <a href="http://telbib.eso.org/?bibcode={$bibcode}">telbib</a></li>                                                             
        }
    </ol></td></tr></table>
    , <h3>Detail (black listed bibcodes rejected)</h3>,
    <table class="table table-condensed">
    <tr><th>Links</th><th>Title</th></tr>
    {
        for $item in $items[not(bibcode=$app:black-bibcodes)]
            let $bibcode := data($item/bibcode)
            let $add-link := if($app:olbindoc//bibcode[.=$bibcode]) then ()
                else <a href="http://jmmc.fr/bibdb/addPub?bibcode={encode-for-uri($bibcode)}"> +olbin</a>
                
            let $color := if($add-link) then "error" else "success"
            return 
                <tr class="{$color}">                    
                    <td>
                        <div>
                        {jmmc-ads:get-link($bibcode,())} / 
                        <a href="http://telbib.eso.org/?bibcode={encode-for-uri($bibcode)}">TelBib</a> / 
                        {$add-link}
                        </div>
                    </td>
                    
                    <td>{data($item/title)}</td>
                </tr>
    }        
    </table>
    )
};

declare function app:arxiv-for-olbin($node as node(), $model as map(*)) {
    let $refs-items := $app:arxiv-for-olbin-doc//ref[not(@done)]
    let $refs := data($refs-items)
    let $refs := for $r in $refs return if(matches($r,"arXiv:")) then $r else "arXiv:"||$r
    (: we can not get all record in on ehost because sorting is lost and no id can help to retrieve record when let $ads-records := jmmc-ads:get-records($refs) :)
    return <table class="table table-condensed">
            {
                for $ref at $pos in $refs
                    (: let $record := $ads-records[$pos] :)
                    return try {
                    let $record := jmmc-ads:get-record($ref)
                    let $bibcode := jmmc-ads:get-bibcode($record)
                    let $title := jmmc-ads:get-title($record)
                    let $author := jmmc-ads:get-first-author($record)
                    let $is-arxiv := if($bibcode=$ref) then true() else if(matches($bibcode, "arXiv")) then true() else false()                    
                    let $is-in-olbin := $app:olbindoc//bibcode[.=$bibcode]
                    let $disable := if($is-in-olbin) then 
                                        for $e in $app:arxiv-for-olbin-doc//ref[.=substring-after($ref,"arXiv:")] return update insert attribute done {$bibcode} into $e 
                                        else ()
                    let $code := if($is-arxiv) then 1 else if ($is-in-olbin) then 3 else 2
                    let $add-link := if($code=2) then <a href="http://jmmc.fr/bibdb/addPub?bibcode={encode-for-uri($bibcode)}">Add in Olbin DB</a> else ()
                    (:  ARXIV-ONLY=1 - PUBLISHED-AND-NOT-IN-OLBIN=2 - PUBLISHED-AND-IN-OLBIN=3 :)
                    let $class := ("warning", "error", "success")[$code]
                    let $info := (<span>Not yet published</span>, <span>{$add-link}</span>, "In Olbin DB")[$code]
                    order by $code, $ref descending
                    return
                        <tr class="{$class}"><td>{$info}</td><td>{jmmc-ads:get-link($ref,())}</td><td>{$bibcode}</td><td>{$title}</td><td>{$author}</td><td>{data($refs-items[$pos]/@subdate)}</td></tr>   
                    } catch * {
                        <tr class="error"><td>{$ref}</td><td>{jmmc-ads:get-link($ref,())}</td><td>--</td><td>--</td><td>--</td><td>--</td></tr>   
                    }
            }
            {
                for $e in $app:olbindoc//e[bibcode[contains(.,"arXiv")]]                    
                    let $ref := ($e/bibcode/text())[1]
                    let $record := jmmc-ads:get-records($ref)[1]
                    let $bibcode := jmmc-ads:get-bibcode($record)
                    let $title := jmmc-ads:get-title($record)
                    let $author := jmmc-ads:get-first-author($record)
                    let $is-arxiv := if($bibcode=$ref) then true() else if(matches($bibcode, "arXiv")) then true() else false()                    
                    let $is-in-olbin := $app:olbindoc//e[bibcode=$bibcode]
                    let $tags := ( for $t in $e/tag/text() order by $t return <span class="label label-warning">{$t}</span>, <br/>, for $t in $is-in-olbin/tag/text() order by $t return <span class="label label-success">{$t}</span>)
                    let $disable := if($is-in-olbin and not (matches($bibcode, "arXiv"))) then 
                                        for $e in $app:arxiv-for-olbin-doc//ref[.=substring-after($ref,"arXiv:")] return update insert attribute done {$bibcode} into $e 
                                        else ()
                    let $code := if($is-arxiv) then 1 else if ($is-in-olbin) then 3 else 2
                    let $link := (<span/>,<a href="http://jmmc.fr/bibdb/addPub?bibcode={encode-for-uri($bibcode)}">Add in Olbin DB</a>,<a href="http://jmmc.fr/bibdb/delPub?bibcode={encode-for-uri($ref)}">Remove from Olbin DB</a>)[$code]
                    (:  ARXIV-ONLY=1 - PUBLISHED-AND-NOT-IN-OLBIN=2 - PUBLISHED-AND-IN-OLBIN=3 :)
                    let $class := ("warning", "error", "error")[$code]   
                    let $info := (<span>Registred in olbin using ArXiv ref but not yet published</span>, <span></span>, <span>Registred in olbin using ArXiv ref and refereed ref {jmmc-ads:get-link($bibcode,())}</span>)[$code]

                    return
                        <tr class="{$class}"><td>{$info}&#160;{$link}</td><td>{jmmc-ads:get-link($ref,())}</td><td>--</td><td>{$title}<br/>{$tags}</td><td>{$author}</td><td>--</td></tr>                                       
            }
            </table>
};

declare function app:add-arxiv-ref($node as node(), $model as map(*), $arxiv-ref as xs:string?) {
        <form method="post">
            <input type="text" name="arxiv-ref" placeholder="1306.2111, arXiv:1306.2111L or 2003arXiv1306.2111L"></input>
            <input type="submit" value="Add new arxiv to check"/>
        </form>        
        ,for $re in $arxiv-ref
        let $r := xmldb:decode($re)
        let $r := normalize-space(tokenize(translate($r, ":v","__"),"_")[last()])
        let $r := (for $i in tokenize($r, "[a-zA-Z]") where $i return $i)[1]
        return 
            if(exists($app:arxiv-for-olbin-doc//ref[.=$r])) then 
                <div class="alert alert-warning alert-dismissible" role="alert">
                    <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true"></span><span class="sr-only">Close</span></button>
                    <strong>Warning!</strong> <b>{$r}</b> already present
                </div>
            else if(empty($r) or $r='') then 
                <div class="alert alert-warning alert-dismissible" role="alert">
                    <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true"></span><span class="sr-only">Close</span></button>
                    <strong>Warning!</strong> empty value
                </div> 
            else (<div class="alert alert-info alert-dismissible" role="alert">
                    <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true"></span><span class="sr-only">Close</span></button>
                    <span>{$r} added for futur check<br/></span></div> ,update insert <ref subdate="{current-dateTime()}">{normalize-space(data($r))}</ref> into $app:arxiv-for-olbin-doc/* )
        
};

declare function app:add-memo-ref($node as node(), $model as map(*), $memo-ref as xs:string?) {
        let $type := "memo"
        let $doc := $app:arxiv-for-olbin-doc
        return 
            (<form method="post">
            <input type="text" name="memo-ref"></input>
            <input type="submit" value="Add memo for missing reference"/>
        </form>        
        ,for $re in $memo-ref
        let $r := xmldb:decode($re)
        let $r := normalize-space(tokenize($r, ":")[last()])
        return 
            if(exists($doc//ref[.=$r])) then 
                <div class="alert alert-warning alert-dismissible" role="alert">
                    <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true"></span><span class="sr-only">Close</span></button>
                    <strong>Warning!</strong> <b>{$r}</b> already present
                </div>
            else if(empty($r) or $r='') then 
                <div class="alert alert-warning alert-dismissible" role="alert">
                    <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true"></span><span class="sr-only">Close</span></button>
                    <strong>Warning!</strong> empty value
                </div> 
            else (<div class="alert alert-info alert-dismissible" role="alert">
                    <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true"></span><span class="sr-only">Close</span></button>
                    <span>{$r} added<br/></span></div> ,
                    update insert <ref type="{$type}" subdate="{current-dateTime()}">{normalize-space(data($r))}</ref> into $doc )
            )
};


declare function app:jmmcList($node as node(), $model as map(*), $tags as xs:string* ) {                                
    let $bibcodesToDisplay := if(exists($tags)) then $config:docmgr-tags-doc//e[tag=$tags]/bibcode else $config:docmgr-tags-doc//e/bibcode 
    let $bibcodesToDisplay := distinct-values($bibcodesToDisplay)
    return  <div>  
        <h1> Publications associated to a jmmc product
        {
            if(exists($tags)) then " filtered by tags : "  || string-join($tags, ", ") else ()
        } ({count($bibcodesToDisplay)})
        </h1>
        <ul class="list-inline inline">{ for $t in distinct-values($config:docmgr-tags-doc//tag) return <li><a href="?tags={$t}">{$t}</a></li>}</ul>
        <p>
        {
            for $bibcode in $bibcodesToDisplay
                let $record:=ads:getRecord($bibcode)
                order by $bibcode
                return 
                <div><a href="{ads:getAdsUrl($bibcode)}">{$record/ads:title/text()}</a></div>
                
        }
        </p>
    </div>
};


(: 
 : TODO: 
 : - try to cleanup $olbindoc
 : 
 :)
declare function app:dbList($node as node(), $model as map(*)) {        
    (: Double Check that uploaded data are well indexed :)           
    let $uris := for $c in $app:category return for $d in xmldb:get-child-resources(concat($config:data-root ,"/",$c,"/")) return concat($config:data-root, "/",$c,"/", $d)    
    let $checkindex :=  for $uri in $uris return 
        try{
            if( ft:has-index($uri) ) then () else trigger:index($uri)
        }catch *{
            util:log("error", concat("indexing ",$uri))  
        }       
        
    let $legend := <p>
            <ul class="inline list-inline"><li><a href="#col2">Olbin</a></li><li><a href="#col1">JMMC</a></li></ul>
            Legend : 
            <ul class="inline list-inline">
                <li><button class="btn-success btn-mini">1</button> : pdf is indexed</li>
                <li><button class="btn-warning btn-mini">1</button> : pdf has not yet been retrieved</li>
                <li><button class="btn-danger btn-mini">1</button> : pdf seems not obvious or can not be retrieved</li>
                <li><button class="btn-success btn-mini">JMMC</button> : tagged JMMC with corresponding products</li>
                <li><button class="btn-warning btn-mini">JMMC</button> : tagged JMMC but require product tags</li>            
            </ul>            
        </p>    
    
    (: show indexed status according verbatim repository lists :)
    return
    <div>
        {
            let $docs := for $e in $app:olbindoc//e order by substring($e/bibcode,1,4) descending , $e/pubdate return $e            
            let $update := ads:cache($docs//bibcode/text())
            return  <div>
            <h1>Olbin</h1>
            <a name="col2"/>
            {$legend} 
            {let $c := count($update) return if ($c=0) then () else <pre>{$c} articles without cached metadata over {count($docs)}</pre>}
        <p>
        <table class="table">
        {
            for $e at $pos in $docs
                let $bibcode:=$e/bibcode
                let $record:=ads:getRecord($bibcode)
                let $a := ads:hasPdfInCache($bibcode)
                let $cache := ads:cache($bibcode)
                let $c := if($a) then "btn-success" else if ($record//ads:link[@type="ARTICLE"]) then "btn-warning" else "btn-danger"            
                let $meta := if($cache) then <button class="btn-danger btn-mini">META</button> else ()
                return <tr>
                <td><a href="{ads:getAdsUrl($bibcode)}">{$e/title/text()}</a></td>
                <td><a href="{concat($config:ads-abs_query-url,"bibcode=",encode-for-uri($bibcode))}">{$bibcode/text()}</a></td>
                <td><button class="{$c} btn-mini">{$pos}</button></td>                
                <td>{$meta}</td>
                <td>{if( $record[@refereed="true"] ) then () else <button class="btn-danger btn-mini">NOT-REFEREED</button>}
                    {if($e/tag[.="JMMC"])then let $color := if ($config:docmgr-tags-doc//e[bibcode=$bibcode]) then "btn-success" else "btn-warning" return
                    <div class="btn-group" data-toggle="buttons-checkbox" id="{$bibcode}">
                    {
                        for $t in $app:jmmctags let $done := if($config:docmgr-tags-doc//e[bibcode=$bibcode and tag=$t]) then "active" else () return <button type="button" class="tagbtn btn btn-mini btn-primary {$done} {$color} ">{$t}</button>
                    }</div>
                    
                    else ()}
                </td><td>
                    
                </td>    
                </tr>
        }
        </table>  
        
        <pre>
        {            
            string-join(("# try to collect verbatim pdf:",
                for $e at $pos in reverse($docs)
                let $bibcode:=$e/bibcode
                let $record:=ads:getRecord($bibcode)
                let $a := ads:hasPdfInCache($bibcode)                
                let $linkurl := replace($record//ads:link[@type="ARTICLE"]/ads:url/text(),"cdsads.u-strasbg.fr","cdsads.u-strasbg.fr.gaelnomade.ujf-grenoble.fr")
                return if($a) then () else if ($linkurl) then "curl --cookie nada -L -o &quot;"||$bibcode||".pdf&quot; &quot;"||$linkurl||"&quot;"  else ()  
                ) ,"&#10;")
        }    
        {            
            string-join(("# try to collect arxiv pdf:",
                for $e at $pos in reverse($docs)
                let $bibcode:=$e/bibcode
                let $record:=ads:getRecord($bibcode)
                let $a := ads:hasPdfInCache($bibcode)                
                let $linkurl := $record//ads:link[@type="PREPRINT"]/ads:url/text()
                return if($a) then () else if ($linkurl) then "curl --cookie nada -L -o &quot;"||$bibcode||".pdf&quot; &quot;"||$linkurl||"&quot;"  else ()  
                ) ,"&#10;")
        }    
        </pre>        
        </p>
        
                
        <h1>JMMC</h1>
        <a name="col1"/>
        {$legend}
        <p>
        <table>
        {
            let $docs := for $d in $app:jmmcdoc//document order by $d/@id return $d
            return
            for $d at $pos in $docs
            let $docname:=concat($d/@id,".", $d/@type)
            let $c := if(util:binary-doc-available(concat($config:data-root,"/jmmc/",$docname))) then "alert-success" else "alert-warning"
            return <tr><td><span class="{$c}">{$pos}</span></td><td><a href="{concat("http://www.jmmc.fr/doc/?search=",$d/@id)}">{concat("",$d/@title)}</a></td></tr>
        }
        </table>            
        </p>
        
        
        <script>
        <![CDATA[
        $( 'body' ).on( 'click', '.tagbtn', function(event) {        
            var action="link";
            if($(this).hasClass( 'active' ) ) { action="unlink"; }
            var bibcode = $(this).parent()[0].getAttribute("id");
            var tag = $(this).text();            
            $.ajax( { url: "manage.html",  data: { action: action,bibcode: bibcode, tag: tag } } )
            .fail(function() { alert( "Sorry can't process your request, please Sign In first" ); })                               
        });            
        ]]>
    </script>
        </div>
        }
    </div>
};


declare function app:form($node as node()*, $model as map(*), $query as xs:string?, $category as xs:string*) {
    let $query := if(exists($query)) then $query else ()
    let $category := if(exists($category)) then $category else tokenize(request:get-cookie-value("category"),",")
    return 
    <div class="span12">
        <form action="" method="GET" class=".form-search">
        <label class="checkbox inline"> Fill next form to query : </label>
            {
                for $c in $app:category
                return 
                    <label class="checkbox inline">
                        {if (contains($category ,$c)) then <input type="checkbox" name="category" value="{$c}" checked="true"/> else <input type="checkbox" name="category" value="{$c}"/> }
                        '{$c}' collection ({count(xmldb:get-child-resources(concat($config:data-root ,"/",$c,"/")))} pdf { if($c="olbin") then "+ "||count(xmldb:get-child-resources(concat($config:data-root ,"/arxiv/")))||" from arxiv"  else () })
                    </label>
            }            
            <br/>
            <input id="query" type="text" size="120" value="{$query}" name="query" class="search-query templates:form-control"/>
            <a href="http://lucene.apache.org/core/3_6_0/queryparsersyntax.html"> ? </a>
            <button class="btn" type="submit">Query</button>
        </form>
    </div>

};

declare function app:getTitle($path as xs:anyURI){
    let $ref := substring-before(replace($path, "^.*/([^/]+)$", "$1"), ".pdf")
    let $ref := xmldb:decode($ref)
    
    let $link  :=   if(matches($path,"/data/jmmc/"))
                    then 
                        concat("http://www.jmmc.fr/doc/?search=",$ref)
                    else
                        concat("http://adsabs.harvard.edu/abs/",$ref)          
    let $title  :=   if(matches($path,"/data/jmmc/"))
                    then 
                        string($app:jmmcdoc//document[@id=$ref]/@title)
                    else
                        $app:olbindoc//e[bibcode=$ref]/title/text()
    let $title := if ($title) then $title else "ERROR while retrieving title for doc : " || $path
    
    return <a href="{$link}" title="{$ref}">{$title}</a>
};

declare function app:getReference($path as xs:anyURI){
    substring-before(replace(xmldb:decode-uri($path), "^.*/([^/]+)$", "$1"), ".pdf")        
};

declare function app:getOlbinElement($path as xs:anyURI){    
    $app:olbindoc//e[bibcode=app:getReference($path)]    
};

declare function app:query($node as node()*, $model as map(*), $query as xs:string?, $category as xs:string*) {        
    let $cookie := if (exists($query)) then response:set-cookie("query",$query, xs:yearMonthDuration('P10Y'), false()) else ()
    let $cookie := if (exists($category)) then response:set-cookie("category",string-join($category,","), xs:yearMonthDuration('P10Y'), false()) else ()
    
    let $category := if (exists($category)) then $category else $app:category
    (: hack to retrieve arxiv :)
    let $category := if("olbin"=$category) then ($category, "arxiv") else $category
    let $paths := for $e in $category return concat($config:data-root,$e,"/")
    
    let $results := ft:search($paths, $query)/search
    
    return    
    <div class="cex-results">
    <h3>{count($results)} documents found for '{$query}' in category {string-join($category, ",")}</h3>
    {
        for $result in $results
        let $fields := $result/field
        (: Retrieve title from title field if available :)
        let $title := app:getTitle($result/@uri)
        let $ref := app:getReference($result/@uri)
        let $e := app:getOlbinElement($result/@uri)
        let $tags := if($e[tag="JMMC"]) then let $color := if($config:docmgr-tags-doc//e[bibcode=$ref and tag]) then "success" else "warning" return <button class="btn-{$color}">JMMC</button> else ()
        let $actions := if(exists($e[tag="JMMC"])) then
            <div class="btn-group" data-toggle="buttons-checkbox" id="{$ref}">
                {
                    for $t in $app:jmmctags let $done := if($config:docmgr-tags-doc//e[bibcode=$ref and tag=$t]) then "active" else () return <button type="button" class="tagbtn btn btn-mini btn-primary {$done}">{$t}</button>
                }
            </div>
            else 
                ()
        order by $ref
        return
            <div class="item">
                <p class="itemhead">{$tags} - {$title} - Score: {$result/@score/string()} &#160; <a href="http://jmmc.fr/bibdb/olbinSearch.php?query={encode-for-uri($ref)}">Olbin</a> <a href="http://jmmc.fr/bibdb/manageJmmc.php#ANCHOR_{encode-for-uri($ref)}">#</a> {$actions}</p>                
                <p class="itemhead">Found matches in {count($fields)} page{if (count($fields) gt 1) then 's' else ''} of the document. {if (count($fields) gt 10) then 'Only matches from the first 10 pages are shown.' else ''}</p>
                {
                    
                    for $field in subsequence($fields, 1, 10)
                    let $page := text:groups($field, "\[\[([0-9]+)")
                    return
                        <p>
                            { concat("page ", $page[2]) }
                            {kwic:summarize($field, <config width="100"/>)}
                        </p>
                }
            </div>
    }
    <script>
        <![CDATA[
        $( 'body' ).on( 'click', '.tagbtn', function(event) {        
            var action="link";
            if($(this).hasClass( 'active' ) ) { action="unlink"; }
            var bibcode = $(this).parent()[0].getAttribute("id");
            var tag = $(this).text();            
            $.ajax( { url: "manage.html",  data: { action: action,bibcode: bibcode, tag: tag } } )
            .fail( function() { alert( "Sorry can't process your request, please Sign In first" ); })                               
        });
        ]]>
    </script>
    </div>
};

declare function app:report($node as node()*, $model as map(*), $update as xs:string?) {
    let $resource-name := "check.html"
    let $content := if(exists($update)) then app:doReport($node,$model) else doc($config:data-root||"/"||$resource-name)
    let $store := if(exists($update)) then xmldb:store($config:data-root, $resource-name, $content) else ()
    return 
        $content
};

declare function app:doReport($node as node()*, $model as map(*)){    
  let $in  := "2010SPIE.7734E.140L,2006A&amp;A...456..789B,2009A&amp;A...502..705C,2010yCat.2300....0L,2011A&amp;A...535A..53B,2008SPIE.7013E..44T"
  let $in2 := "2010SPIE.7734E..4EL,2010SPIE.7734E..84L,2010SPIE.7734E..83M,2012ASPC..461..379L,2011ASPC..442..489D,2010SPIE.7734E.107M,2012yCat..74140108B,2011MNRAS.414..108B,2010SPIE.7734E.138M,2011Msngr.145....7W,2010yCat.2300....0L,2011A&amp;A...535A..53B,2010SPIE.7734E.140L,2012SPIE.8445E..3FM,"
  (: 2012A&amp;ARv..20...53B,2011A&amp;A...533A..64R :)
  (: let $in := "2012A&amp;ARv..20...53B,2010SPIE.7734E.140L,2006A&amp;A...456..789B" :)
  let $in3 := ("2017yCat.2346....0B", "2016SPIE.9907E..28M", "2016SPIE.9907E..11B", "2016SPIE.9907E..3VH", "2016A&amp;A...589A.112C")
  
  let $bibcodes := for $e in distinct-values(( tokenize($in||","|| $in2,","), $in3)) where $e order by $e descending return $e
  
  (:let $bibcodes := distinct-values(tokenize("2010yCat.2300....0L,2010SPIE.7734E.140L",",")):)

let $list := <l>
{
for $b in $bibcodes
let $adsUri := xs:anyURI( concat($config:ads-ref_query-url, "bibcode=",encode-for-uri($b),"&amp;refs=REFCIT"))
return
<e>  
  <bibcode>{$b}</bibcode>  
    {     
        for $r in doc($adsUri)//ads:record[@refereed]
        return
        <r>
        <bibcode>{$r/ads:bibcode/text()}</bibcode>
        <title>{$r/ads:title/text()}</title>            
        </r>       
       } 
  <br/>
</e>
}
</l>

let $list_bibcodes := for $e in distinct-values($list//r/bibcode/text()) order by $e return normalize-space($e)
let $bibdb_bibcodes := for $e in distinct-values($app:olbindoc//bibcode/text()) order by $e return normalize-space(replace($e, "%26", "&amp;"))
let $inOidb_bibcodes := distinct-values($list_bibcodes[.=$bibdb_bibcodes])
let $notInOidb_bibcodes := distinct-values($list_bibcodes[not(.=$bibdb_bibcodes)])

let $missing_bibcodes := $app:olbindoc//e[not(tag="JMMC") and bibcode=$inOidb_bibcodes]/bibcode
let $res := <div>
    
    <pre>not in olbin :{count($notInOidb_bibcodes)}
    in olbin : {count($inOidb_bibcodes)}</pre>
    In olbin but not tagged:<ol>{for $m in $missing_bibcodes order by $m descending return <li><a href="http://apps.jmmc.fr/bibdb/manageJmmc?#ANCHOR_{$m}">{$m/text()}</a></li>}</ol>
    Not in olbin:<br/>
    <ol>
        {for $m in $notInOidb_bibcodes order by $m descending return <li>{if ( $m=$app:black-bibcodes) then <strike>{$m}</strike> else $m}</li>}</ol>
    
    <ul>{
        for $e in $list/e return 
            <li><a href="{ads:getAdsUrl($e/bibcode)}">citations of <em>{$e/bibcode/text()}</em></a><br/>
                <ol>{
                    for $r in $e//r                    
                    let $class := if($r/bibcode=$bibdb_bibcodes) then if($r/bibcode=$missing_bibcodes) then "alert-error" else "alert-success" else ()
                    return <li class="{$class}">{$r/bibcode/text()}&#160; <a href="{ads:getAdsUrl($r/bibcode)}">{$r/title/text()}</a></li>                            
                }</ol>
            </li>                
    }</ul>
    
    {jmmc-ads:get-html(jmmc-ads:get-records($notInOidb_bibcodes),100)}
    
    </div>
return $res    
};

declare function ads:getAdsUrl($bibcode as xs:string) {
    $config:ads-abs-url||encode-for-uri($bibcode)
};

declare function ads:getRecord($bibcode) {
    $config:ads-cache-doc//ads:bibcode[.=$bibcode]/parent::ads:record
};

declare function ads:cache($bibcode) {
    let $currents := $config:ads-cache-doc//ads:bibcode
    let $createDoc := if(empty($currents)) then xmldb:store($config:data-root||"ads", $config:ads-cache-filename, <cache/>) else ()
    
    let $missing := $bibcode[not(.=$currents)]
    
    let $encodedBibcodes := for $e in $missing return encode-for-uri($e)
    
    let $chunkSize := 50
    let $split := for $loop in 0 to 0+round(count($encodedBibcodes) div $chunkSize)
                    let $from := $loop*$chunkSize                    
                    let $seq := subsequence($encodedBibcodes, $from, $chunkSize)
                    (: build url on top of the given sequence of bibcodes:)
                    let $missingRecordsUrl := concat($config:ads-abs_query-url,"bibcode=", string-join($seq, "&amp;bibcode="))
                    (: peform remote request :)
                    let $missingRecords := if(exists($seq)) then try{doc($missingRecordsUrl)//ads:record} catch *{ () } else ()
                    (: do log :)
                    let $update := if(exists($seq)) then update insert <a href="{$missingRecordsUrl}">update on {current-dateTime()}: requested {count($seq)}, returned {count($missingRecords[.//ads:bibcode=$missing])} over {count($missingRecords)}  </a> into $config:ads-cache-doc/cache else ()
                    (: and insert retrieved records if any :)
                    let $update := for $r in $missingRecords[.//ads:bibcode=$missing] return update insert $r into $config:ads-cache-doc/cache
                
                    return <span> {count($missingRecords)} {$config:data-root||$config:ads-cache-filename}<a href="{$missingRecordsUrl}">updated articles</a> </span>
    
    return $missing
};

declare function ads:hasPdfInCache($bibcode as xs:string) {        
    let $currents := $config:ads-cache-doc//ads:bibcode
    let $createDoc := if(empty($currents)) then xmldb:store($config:data-root||"ads", $config:ads-cache-filename, <cache/>) else ()
    
    let $record := ads:getRecord($bibcode)
    let $check := if($record) then  () else util:log("error", <p>can't retrieve record in cache for bibcode='{$bibcode}' </p>)
    
    let $openDatastore := $config:data-root||"olbin/"
    let $arxivDatastore := $config:data-root||"arxiv/"
    let $filename := $bibcode||".pdf"
    let $available := 
    try {
         util:binary-doc-available($openDatastore||$filename) or util:binary-doc-available($arxivDatastore||$filename)    
    } catch * {
        false()
    }
    
    
    (: get arxiv link : )
    let $link := subsequence( 
                (collection($config:data-root)//ads:record[ads:bibcode=$bibcode]//ads:link[@type="ARTICLE" and @access="open"]
                ,collection($config:data-root)//ads:record[ads:bibcode=$bibcode]//ads:link[@type="PREPRINT"]
                )
                , 1,1)/ads:url/text() 
    :)
    
    let $openUrl := if( false()) then $record//ads:link[@type="ARTICLE" and @access="open"]/ads:url/text() else ()
    let $arxivUrl := if( true() ) then $record//ads:link[@type="PREPRINT"]/ads:url/text() else ()

    (:
    next code try to get pdf and store them in db but fails
    :)
    let $available := if ( $available ) then $available                    
        else if ($openUrl) then            
            let $test:=string(doc($openUrl)//*[@name="citation_pdf_url"]/@content)
            let $log := util:log("error", <p>retrieving {$openUrl} ({$test})</p>)
            let $openUrl := if($test) then $test else $openUrl
            let $pdf := httpclient:get( xs:anyURI($openUrl), false(), () )/httpclient:body/text()
            let $store := if($pdf) then xmldb:store($openDatastore, $filename, xs:base64Binary($pdf)) else ()
            let $update := if($store) then update insert <a href="{$openUrl}">pdf retrieved on {current-dateTime()} for {$bibcode} : {$store} </a> into $config:ads-cache-doc/cache else util:log("error", <p>pdf not retrieved for {$bibcode} </p>)              
                return util:binary-doc-available($openDatastore||$filename)          
        else if ($arxivUrl) then
            let $pdfUrl:=string(doc($arxivUrl)//*[@name="citation_pdf_url"]/@content)
            let $log := util:log("error", <p>retrieving {$arxivUrl} / {$pdfUrl} </p>)
            let $pdf := httpclient:get( xs:anyURI($pdfUrl), false(), () )/httpclient:body/text() 
            let $store := xmldb:store($arxivDatastore, $filename, xs:base64Binary($pdf))                                
            let $update := update insert <a href="{$pdfUrl}">pdf retrieved on {current-dateTime()} for {$bibcode} : {$store} </a> into $config:ads-cache-doc/cache                    
                return util:binary-doc-available($arxivDatastore||$filename)          
        else
            ()
            (:util:log("error", <p>Sorry can't retrieve pdf for {$bibcode} : {count(collection($config:data-root)//ads:record[ads:bibcode=$bibcode])}</p>):)

    (: :) 
  
  return $available
};

declare function app:manageAction($action as xs:string?, $bibcode as xs:string?, $tag as xs:string?) 
{
    if(not(jmmc-auth:isLogged())) then 
        (response:set-status-code(401))
    else if($action="link" and $bibcode and $tag) then
        if($config:docmgr-tags-doc) then
            update insert   <e><bibcode>{$bibcode}</bibcode><tag>{$tag}</tag><date>{current-dateTime()}</date>
                                {jmmc-auth:getInfo()}
                            </e> into $config:docmgr-tags-doc/tags
        else
            ()
    else if ($action="unlink"  and $bibcode and $tag) then
        update rename $config:docmgr-tags-doc//e[bibcode=$bibcode and tag=$tag]/bibcode as "oldbibcode"    
    else 
        <div class="alert alert-error">action ignored, please provide action bibcode and tag parameters </div>
};

declare function app:manage($node as node()*, $model as map(*), $action as xs:string?, $bibcode as xs:string?, $tag as xs:string?)  
{
    if($action) then 
       <div>{app:manageAction($action, $bibcode, $tag)}</div>
    else        
        <div> 
            Here comes the referenced publications:
            <ul>
            {            
                let $tags := distinct-values($config:docmgr-tags-doc//tag)            
                return 
                for $t in $tags
                return 
                    (<li>{$t}</li>,
                    <ol>
                        {for $e in $config:docmgr-tags-doc//e[tag=$t and bibcode] order by $e/bibcode return <li>{$e/bibcode/text()} - {$e/date/text()} - {$e/author/name/text()} </li>}
                    </ol>
                    )
            }
            </ul>
            
        {
            let $es := $config:docmgr-tags-doc//e
            let $tags := distinct-values($es/tag)            
            let $bibcodes := $es/bibcode
            let $years := distinct-values( for $e in $bibcodes return substring($e, 1,4) )        
            return 
                for $e in (
                string-join(("YEAR", $tags),",")
                ,for $y in $years
                order by $y
                return string-join(($y,for $t in $tags return count($es[starts-with(bibcode, $y) and tag=$t])), ",")
                ) return (<br/>,$e)
        }
            
        </div>       
};

declare function app:rssItems($maxItems) 
{
    let $els := for $e in $config:docmgr-tags-doc//e[date and bibcode]
                    order by $e/date descending return $e
    for $e in subsequence($els, 0, $maxItems)
    return <item>
        <link>{ads:getAdsUrl($e/bibcode)}</link>
        <title>new submitted tag : {$e/tag/text()}</title>
        <description>                
                {serialize(<p>{ads:getRecord($e/bibcode)//ads:title/text()}        
                <br/>{string-join( $config:docmgr-tags-doc//e[bibcode=$e/bibcode]/tag,", ") }</p>
                )}
        </description>
        <pubDate>{jmmc-dateutil:ISO8601toRFC822($e/date)}</pubDate>        
    </item> 
};

declare function app:stats($node as node()*, $model as map(*)) 
{
    <table class="table table-condensed">
        <tr><th>Date</th><th>Cite Jmmc</th><th>Olbin</th></tr>        
        {
         for $by_year in $app:olbindoc//e group by $year:=substring($by_year/bibcode,1,4) order by $year return
             if(number($year)>=1990) then <tr><td>{$year}</td><td>{count($by_year[tag="JMMC"])}</td><td>{count($by_year[not(tag="JMMC")])}</td></tr> else ()
        }
    </table>
};

declare function app:olbin-list($node as node()*, $model as map(*)) 
{
    for $by_year in $app:olbindoc//e group by $year:=substring($by_year/bibcode,1,4) order by $year 
    return
        <div>
            <h3>{$year} ({count($by_year)})</h3>
            <table class="table table-condensed">
            {
                let $bibcodes := $by_year//bibcode
                return 
                    for $r in jmmc-ads:get-records($bibcodes) (: doc("/db/apps/jmmc-resources/ads-cache.xml")//ads:record[ads:bibcode=$bibcodes]  :)
                        return 
                            <tr><td>{jmmc-ads:get-html($r,100)}</td></tr>
            }
            </table>
        </div>
};

declare function app:jmmc-list($node as node()*, $model as map(*)) 
{
    let $tags := for $t in distinct-values($config:docmgr-tags-doc//tag) order by $t return $t
    
    let $olbin-bibcodes := distinct-values($app:olbindoc//bibcode)
    
    (: next section notify and update docmgr-tags-doc from the selection provided on the olbin web site :)
    let $top := if ( false() ) then <table>
        { for $tag in $tags
        let $olbin-bibcodes := $app:olbindoc//e[tag=$tag]/bibcode
        let $tagged-bibcodes := $config:docmgr-tags-doc//e[tag=$tag]/bibcode
        let $to-store := $olbin-bibcodes[not(.=$tagged-bibcodes)]
        let $update := for $bibcode in data($to-store) return update insert   <e><bibcode>{$bibcode}</bibcode><tag>{$tag}</tag><date>{current-dateTime()}</date>
                                {jmmc-auth:getInfo()}
                            </e> into $config:docmgr-tags-doc/tags
        return
        <tr>
            <td> added for <b>{$tag}</b></td>
            <td>
                { string-join( $to-store , ", " ) }
            </td>
        </tr>
        }
        </table>
        else ()
        
    let $header := <div id="toc"><ul class="list-inline inline">{
            for $by_tag in $config:docmgr-tags-doc//e group by $tag := $by_tag/tag order by $tag
                return <li><a href="#{$tag/text()}"> {$tag/text()} ({count($by_tag/bibcode)}) </a>    </li>
        }        
        </ul></div>    
        
    let $data := for $by_tag in $config:docmgr-tags-doc//e group by $tag := $by_tag/tag  order by $tag
    return <div>
            <h3 id="{$tag/text()}">{$tag/text()} ({count($by_tag/bibcode)}) <a href="#toc"><span class="glyphicon glyphicon-chevron-up  icon-arrow-up" /></a></h3>
            <table class="table table-condensed">
            {               
                let $records := for $b in $by_tag/bibcode/text() return jmmc-ads:get-records($b)[1]
                
                return for $r in $records
                    let $bib := data($r/ads:bibcode)
                    order by $bib descending
                    return 
                    <tr><td>{if($olbin-bibcodes = $bib) then () else <span class="glyphicon glyphicon-chevron-up  icon-arrow-up"></span>}{jmmc-ads:get-html($r,4)}</td></tr>
               
            }
            </table>
        </div>
        return ($top, $header, $data)
};