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

<dspace:layout locbar="noLink" titlekey="jsp.about.title" >

<div class="row">
  <div class="info-page col-md-9">
    <header class="page-title-area"><h1>NYU Faculty Digital Archive Guidelines</h1>
    </header>
    <p>The Faculty Digital Archive (FDA) is a service provided jointly by the NYU Libraries and NYU IT on behalf of the departments and academic organizations of NYU. The FDA enables contributors to archive and share via internet download their scholarly work in any of a wide range of digital formats. It is available at <a href="https://archive.nyu.edu/">archive.nyu.edu</a>.</p>
    <p>NYU reserves the right to change, at any time, at its sole discretion, the provisions of the service and these terms.</p>
    <h2>Eligibility</h2>
    <p>The content in the Faculty Digital Archive represents the research, scholarship, and intellectual output of the NYU community. Materials authored or published by the following NYU affiliates are eligible for deposit:</p>
    <ul>
      <li>Any NYU research unit, institute, center, department, or university partner with NYU credentials</li>
      <li>NYU full-time permanent faculty</li>
      <li>NYU students and affiliated researchers with authorization from a sponsoring department or faculty member</li>
    </ul>
    <p>The academic units or individual faculty members decide what content to put into their respective collections, provided they have the right to share it according to the terms of the <a href="#">FDA deposit license</a>. <a href="https://docs.google.com/document/d/1jRUhOoRq7Rwvsrd8b5nHYI74HhfpYJ02i-vv0OdAOqE/edit?usp=sharing">LINK TO NEW PAGE</a></p>
    <p>Types of content may include, but are not limited to:</p>
    <ul>
      <li>Submitted manuscripts (as sent to journals for peer review)</li>
      <li>Accepted versions of articles (author's final peer-reviewed drafts)</li>
      <li>Published versions (publisher-created files, if publisher allows this; see Sherpa Romeo database of publisher copyright policies, <a href="http://www.sherpa.ac.uk/romeo/index.php">http://www.sherpa.ac.uk/romeo/index.php</a> )</li>
      <li>Gray literature (conference papers, presentations, research reports, technical reports</li>
      <li>NYU dissertations and theses (final, approved works submitted through the department and/or school)</li>
      <li>Negative results or work that represents a completed result but that will not be published (though not work in progress)</li>
      <li>Data sets</li>
      <li>Images, video</li>
      <li>Code</li>
      <li>Multi-part items consisting of primary file plus supplementary material</li>
    </ul>
    <h2>Open Access</h2>
    <p>The purpose of the Faculty Digital Archive is to provide stable, long-term public access to digital content produced by eligible members of the NYU community. By default, material deposited in the FDA will be openly accessible and available for download worldwide over the Web.</p>
    <p>Under certain circumstances, collection owners may impose restrictions or temporary embargoes on worldwide open access. Access restrictions are set during the deposit process, but may be changed at a later date.</p>
    <p>The following access restrictions and embargoes are allowed:</p>
    <ul>
      <li>Access may be restricted to the NYU community (that is, all those with a current NYU netID and password), or to all members of an NYU school. This restriction may be temporary or permanent.
      </li>
      <li>Access may be temporarily blocked (to any user) for an embargo period normally not to exceed two years. After the embargo period, the content will be openly accessible worldwide. Metadata/citation information will be visible for embargoed items, so they will be discoverable by FDA search and search engines.
      </li>
      <li>Any embargoed or restricted item in the FDA must contain contact information for the content creator (not for a designated depositor), so that end users who wish to gain access may request it.
      </li>
    </ul>
    <p>Requests for restrictions on access should be addressed to FDA staff at archive.help@nyu.edu.</p>
    <p>Research content that contains highly sensitive or confidential information may not be appropriate for deposit in the FDA. FDA staff can recommend alternative repository solutions.</p>
    <h2>Metadata</h2>
    <p>Accurate metadata enables effective discovery and search of FDA content. The following fields are required for all content. FDA staff can assist with additional metadata needs, including custom templates.</p>
    <ul>
      <li>Author/creator (may have multiple authors)</li>
      <li>Title</li>
      <li>Date (may be date published, date deposited, or other as appropriate)</li>
      <li>Rights statement (see next section for details)</li>
      <li>Contact information for the content creator or rights holder</li>
    </ul>
    <h2>Rights statement requirements</h2>
    <p>All content deposited in the FDA must be accompanied, as appropriate, by either a Creative Commons license (<a href="https://creativecommons.org/">creativecommons.org</a>) or one of the standard international rights statements offered by <a href="http://rightsstatements.org/">RightsStatements.org</a>. FDA staff can provide guidance on which is most appropriate for specific content and creators' interests. </p>
    <h2>File Storage Quotas</h2>
    <p>There are currently no restrictions on the amount of material that may be deposited. There are, however, technical limitations on depositing large files (over 3 gb) through the web interface. FDA staff can advise on options for depositing large files and large sets of files.</p>
    <p>If any collection's storage reaches 2 TB, the FDA team may contact the collection owner to discuss retention plans.</p>
    <h2>Preservation commitment</h2>
    <p>NYU is committed to responsible and sustainable management of works deposited in the FDA and to ensuring long-term access to those works. The FDA will provide storage and backup services, fixity checks, and periodic refreshment services. All work deposited in the FDA will be assigned a persistent handle URL for citability and sustainability.</p>
    <p>Content will be preserved at the bit level, in the digital format submitted to the FDA. We can provide guidance about the most preservable formats for various types of content. </p>
    <h2>Removing items</h2>
    <p>The FDA is intended to provide persistent access to deposited material. Under certain circumstances, however, it may be necessary to remove material from the FDA. A request for removal should be directed to archive.help@nyu.edu and include the reasons for withdrawal. FDA staff may contact the requester for additional information. Since the goal of FDA is persistent long-term access, metadata records will be retained for all withdrawn content, with information about the date of removal.</p>
    <p>When leaving the university, content owners may leave their material in the FDA. FDA staff can help with exporting content and structured metadata when needed. </p>
    <h2>Rights and intellectual ownership</h2>
    <p>Collection owners are only permitted to deposit content for which they own the rights, have permission to share in this way, or which is in the public domain. Each deposit requires that collection owners grant a nonexclusive license to NYU for the distribution of their content through the FDA platform. This nonexclusive license in no way limits the rights of the collection owner or original rights holder and is only for the purpose of ensuring access to the content through the FDA. For more information on copyright ownership and permissions, please see the <a href="http://guides.nyu.edu/copyright">NYU Libraries' Copyright Research Guide</a>.</p>
    <h2>Take-down policy</h2>
    <p>NYU reserves the right to remove items from the FDA temporarily or permanently if there is reasonable suspicion that the materials violate the intellectual property or other rights of third parties. </p>
  </div>
</div>

</dspace:layout>
