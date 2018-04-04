xquery version "3.0";

import module namespace config="http://apps.jmmc.fr/exist/apps/docmgr/config" at "config.xqm";

import module namespace app="http://apps.jmmc.fr/exist/apps/docmgr/templates" at "app.xql";

declare function local:words-to-camel-case
  ( $arg as xs:string? )  as xs:string {
     string-join((tokenize($arg,'\s+')[1],
       for $word in tokenize($arg,'\s+')[position() > 1]
        return concat(upper-case(substring($word,1,1)), substring($word,2))
      ,''))
};


declare function local:do($node as node(), $model as map(*)?) {
let $records := $app:olbindoc//e
let $categories := $app:olbindoc//category
let $node := $node
return ( for $r in $records
    return  
        <record>
            { 
                $r/*,
(:                for $c in $categories[tag=$r/tag]/name/text() return <category>{$c}</category>:)
(:                for $c in $categories return element {local:words-to-camel-case($c/name)}{for $tag in $r/tag[.=$c/tag] return $tag}:)
                for $c in $categories return element {local:words-to-camel-case($c/name)}{string-join($r/tag[.=$c/tag], "/")}
            }
            
            
            
            
        </record>,
        <json>
            {        
                for $c in $categories 
                    let $name := replace($c/name,"HIDDEN","JMMC")
                    let $id := local:words-to-camel-case($name)
                    let $e := <e>"${$id}": {{
       "label": "{$name}",
       "visible": false,
       "get":   "content.json.{$id}.#text",
       "default":"",
       "parseCSV" : "/",
       "foreach": {{
         "trim": true
        }},
        "remove":""
    }},
      </e>
            return $e/text()
            }  
    </json>,
    <json>
            {        
                for $c in $categories 
                    let $name := replace($c/name,"HIDDEN","JMMC")
                    let $id := local:words-to-camel-case($name)
                    let $e := <e>{{
        "field": "{$id}",
        "type": "pie",
        "title": "{$name}",
        "facets": [
            {{"label": "Journal", "path": "journal" }},
            {{"label": "Years", "path": "year" }},
            {
                let $lines := 
                    for $c2 in $categories let $name2 := replace($c2/name,"HIDDEN","JMMC") let $id2 := local:words-to-camel-case($name2)
                        return '            {"label": "'||$name2||'", "path": "'||$id2||'" }'                    
                return string-join($lines, ",&#10;")
            }
        ]
      }},
      </e>
            return $e/text()
            }        
    </json>)
};

<records>
    {local:do(<a/>,())}
</records>