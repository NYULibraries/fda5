<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Footer for home page
  --%>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>

<%
    String sidebar = (String) request.getAttribute("dspace.layout.sidebar");
%>

            <%-- Right-hand side bar if appropriate --%>
<%
    if (sidebar != null)
    {
%>
	</div>
	<div class="col-md-3"><%= sidebar %></div>
    </div>       
<%
    }
%>
</div>
</main>
            <%-- Page footer --%>
<footer class="navbar navbar-inverse">
    <div class="footer-holder container">
    <div class="f-1"><a href="#">About the Archive</a> | <a href="#">Help</a> | <a href="#">Contact</a></div>
    <div class="f-2">Powered by <a target="_blank" href="http://dlib.nyu.edu/dlts">NYU DLTS</a> and <a target="_blank" href="http://www.dspace.org">DSpace</a> </div>
    </div>
</footer>

    </body>
</html>