<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - About page JSP
  -
  --%>

<%@page import="org.dspace.content.Bitstream"%>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="java.io.File" %>
<%@ page import="java.util.Enumeration"%>
<%@ page import="java.util.Locale"%>
<%@ page import="javax.servlet.jsp.jstl.core.*" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.core.Constants" %>

<dspace:layout locbar="noLink" titlekey="jsp.home.title" >

<div class="row">
<div class="info-page col-md-9">
<header class="page-title-area"><h2>About the Archive</h2></header>
<h3>What is the Faculty Digital Archive (FDA)?</h3>
<p>The Faculty Digital Archive is a highly visible repository of NYU scholarship, allowing digital works—text, audio, video, data, and more—to be reliably shared and securely stored. Collections may be made freely available worldwide, offered to NYU only, or restricted to a specific group. <a href="http://www.nyu.edu/its/faculty/fda" class="readmore">more info</a></p>
<h3>Who can deposit material in the FDA?</h3>
<p>Full-time faculty may deposit their research—unpublished and, in many cases, published—in the FDA. Departments, centers, or institutes may also use the FDA to distribute working papers, technical reports, or other research material. <a href="http://www.nyu.edu/its/faculty/fda" class="readmore">more info</a></p>
<h3>Who can access the FDA?</h3>
<p>By default, content in the FDA is world-readable, unless collection owners choose to restrict access. <a href="http://www.nyu.edu/its/faculty/fda"class="readmore">more info</a></p>
<h3>Finding material</h3>
<p>You can browse or search the FDA using the Browse and Search links in the navigation menu to the top of every page. Collections and items in the FDA all have a URL that is a permanent link--it will always work, and can be used in citations. <a href="http://www.nyu.edu/its/faculty/fda" class="readmore">more info</a></p>
<h3>Restricted material</h3>
<p>While most of the collections in the FDA are open to anyone on the internet, some are restricted by their owners. If you have questions about restricted resources, please write to <a href="mailto:archive.help@nyu.edu">archive.help@nyu.edu</a>.</p>
<h3>Creative Commons Licenses</h3>
<p>We encourage scholars to use Creative Commons licenses where possible in order to maximize the impact and reach of their work. These licenses work along with your copyright, allowing you to share materials as you wish, without readers having to contact you for permission. To learn more and select the correct license for your work, visit the Libraries&rsquo; Creative Commons <a href="http://guides.nyu.edu/c.php?g=276978&p=1846699" class="readmore">research guide</a> or contact the Scholarly Communication Librarian, April Hathcock, april.hathcock@nyu.edu.</p>
<h3>Questions and Account setup</h3>
<p>For more information on the FDA, to request space for your materials, or for help with an existing collection, visit our <a href="https://nyu.service-now.com/servicelink/search_results.do?sysparm_search=FDA" class="readmore">Service Link documentation</a> or e-mail queries to archive.help@nyu.edu.</p>
<a name="rights"></a>
<h3>Rights</h3>
<p>The contents of the FDA may be subject to copyright, be offered under a Creative Commons license, or be in the public domain. Please check items for rights statements. For information about NYU’s copyright policy, see <a href="http://www.nyu.edu/footer/copyright-and-fair-use.html">http://www.nyu.edu/footer/copyright-and-fair-use.html</a>.</p></div></div>

</dspace:layout>
