xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://apps.jmmc.fr/exist/apps/docmgr/config";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";

declare namespace  ads="http://ads.harvard.edu/schema/abs/1.1/abstracts";



(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:data-root := $config:app-root || "-data/data/";

declare variable $config:local-data-root := $config:app-root || "/data/";

declare variable $config:ads-cache-filename := "cache.xml";
declare variable $config:ads-cache-doc := doc($config:app-root || "-data/data/ads/"||$config:ads-cache-filename);

declare variable $config:docmgr-tags-filename := "docmgr-tags.xml";
declare variable $config:docmgr-tags-doc := doc($config:app-root || "-data/data/"||$config:docmgr-tags-filename);


(: declare variable $config:ads-host := "http://adsabs.harvard.edu"; :)
declare variable $config:ads-host := "http://cdsads.u-strasbg.fr";
declare variable $config:ads-abs-url := $config:ads-host||"/abs/";
declare variable $config:ads-abs_query-url := $config:ads-host||"/cgi-bin/nph-abs_connect?data_type=XML&amp;";
declare variable $config:ads-ref_query-url := $config:ads-host||"/cgi-bin/nph-ref_query?data_type=XML&amp;";



declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
  $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};