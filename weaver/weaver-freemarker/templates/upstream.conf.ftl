upstream ${app_name} {
<#list upstreams as srv>
    server ${srv.host}:${srv.port} weight=${srv.weight};
</#list>
}
