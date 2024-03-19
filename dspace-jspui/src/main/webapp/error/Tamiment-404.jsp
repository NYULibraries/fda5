<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Tamiment Library error message page
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ page isErrorPage="true" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"
    prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.core.Context" %>

<%
    Context context = null;

	try
	{
		context = UIUtil.obtainContext(request);
%>

<dspace:layout titlekey="jsp.error.404.title">

    <%-- <h1>Document Not Found</h1> --%>
    <h1><fmt:message key="jsp.error.404.title"/></h1>
    <%-- <p>The document you are trying to access has not been found on the server.</p> --%>
    <p><fmt:message key="jsp.error.404.text1"/></p>
    <%-- <p>Tamiment Library & Robert F. Wagner Labor Archives content can be searched from the NYU Libraries website, <a href="https://specialcollections.library.nyu.edu/search">https://specialcollections.library.nyu.edu/search</a>.</p> --%>
 
</dspace:layout>

<%
	}
	finally
	{
	    if (context != null && context.isValid())
	        context.abort();
	}
%>