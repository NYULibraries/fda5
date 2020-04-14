<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Home page JSP
  -
  - Attributes:
  -    communities - Community[] all communities in DSpace
  -    recent.submissions - RecetSubmissions
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
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.core.NewsManager" %>
<%@ page import="java.util.Map" %>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.core.Constants" %>
<dspace:layout locbar="noLink" titlekey="jsp.home.help" feedData="<%= feedData %>">

          <div class="row">
            <div class="col-md-8 ">
              <div class="brand">
             <h1 class="sr-only" id="page-title">NYU Faculty Digital Archive Homepage</h1>
                <p>The Faculty Digital Archive (FDA) is a highly visible repository of NYU scholarship, allowing digital works—text, audio, video, data, and more—to be reliably shared and securely stored. Collections may be made freely available worldwide, offered to NYU only, or restricted to a specific group.</p>
                <p>Full-time faculty may contribute their research—unpublished and, in many cases, published—in the FDA. Departments, centers, or institutes may use the FDA to distribute their working papers, technical reports, or other research material. <a href="/about" class="readmore" aria-label="Read more about the NYU Faculty Digital Archive">Read more...</a></p>
              </div>

<section class="search-area" role="search">
  <h2 class="sr-only">Search the archive</h2>
  <form method="get" action="/simple-search" class="simplest-search">
    <div class="form-group-flex">
      <div class="input-hold">
      <input type="text" aria-label="search" class="form-control" placeholder="Search titles, authors, keywords..." name="query" id="tequery" ></div>
      <div class="button-hold">   <button type="submit" aria-label="submit" class="btn btn-primary"><span role="presentation" class="glyphicon glyphicon-search"></span></button></div>
    </div>
  </form>
 </section>

                </div>
            </div>

<%
if (mostdownloaded != null && mostdownloaded.count() > 0)
{
%>
       <section class="col-md-4 sidebar">
                     <div class="panel panel-primary most-downloaded">
                       <div class="panel-heading">
                        <h2 class="panel-title">Most downloaded</h2></div>
                       <div class="panel-body">

                    <%

                    for (Item item : mostdownloaded.getMostDownloaded())
                    {

                      if(item.isPublic()) {
                        Collection col=item.getCollections()[0];
                        Metadatum[] dcv = item.getMetadata("dc", "title", null, Item.ANY);
                        String displayTitle = "Untitled";
                        if (dcv != null & dcv.length > 0)
                        {
                            displayTitle = dcv[0].value;
                        }
                        dcv = item.getMetadata("dc", "contributor", "author", Item.ANY);
                        Metadatum[] authors =dcv;

                %>
                    <article >
                    <div class="communityflag"><span>Collection:</span>
                        <a href="<%= request.getContextPath() %>/handle/<%=col.getHandle() %>" ><%= col.getName()  %></a></div>
                        <h3 class="article-title"><a href="<%= request.getContextPath() %>/handle/<%=item.getHandle() %>"><%= displayTitle %></a></h3>
                        <% if (dcv!=null&&dcv.length>0)
                            {
                             for(int i=0;i<authors.length;i++)
                             {
                               String authorQuery=""+request.getContextPath()+"/simple-search?filterquery="
                                             +URLEncoder.encode(authors[i].value,"UTF-8")
                                             + "&amp;filtername="+URLEncoder.encode("author","UTF-8")+"&amp;filtertype="
                                             +URLEncoder.encode("equals","UTF-8");
                        %>

                             <div class="authors">
                             <a class="authors" href="<%=authorQuery %>"> <%= StringUtils.abbreviate(authors[i].value,36) %></a>
                             </div>
                           <% }
                           } %>
                   </article>
                  <%
                   }
                  }

<<<<<<< HEAD
%>     </div>
        </div>
            </section> <!-- end col 4 -->
          </div> <!-- end col row  -->
<% } %>
=======

  <h2>FACULTY DIGITAL ARCHIVE APPLICATION HELP<br /></h2>
  <table>
    <tr>
    <td><p>This page provides a quick reference to activities and terms related to this application. </p><p>For more information on the Faculty Digital Archive service, to request an account to publish your materials, or for help with an existing collection, visit our <a href="https://nyu.service-now.com/servicelink/search_results.do?sysparm_rs=Faculty%20Digital%20Archive">Service Link documentation</a> or e-mail queries to the support team at archive.help@nyu.edu.
    </td>
    </tr>
    </table>
    <h3><a href="#browse">Browse</a></h3>
    <h3><a href="#login">Sign into FDA </a></h3>
    <h3><a href="#search">Search</a></h3>
    <h3><a href="#advanced">Advanced Search<a></h4>
    <h3><a href="#communities">Communities</a></h3>
    <h3><a href="#collections">Collections</a></h3>
    <h3><a href="#submit">Submit</a></h3>
     <h3><a href="#modify">Modify</a></h3>
    <h3><a href="#formats">File Formats</a></h3>
    <h3><a href="#handles">Handles </a></h3>
    <h3><a href="#mydspace">My FDA </a></h3>
    <h3><a href="#subscribe">Receive email updates </a></h3>
  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="browse"></a><strong> BROWSE</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p><strong>Browse</strong> allows you to go through a list of items in some specified order:</p>
  <blockquote>
  <p><strong>Browse by Communities and Collections </strong> takes you through the communities in alphabetical
  order and allows you to see the subcommunities and collections within each community. NYU schools and colleges are represented by top-level Communities, in which faculty work is organized into Collections.</p>
  <p><strong>Browse by Issue Date </strong>allows you to move through a list of all items in the FDA in reverse chronological order (most recent first).</p>
  <p><strong>Browse by Author</strong> allows you to move through an alphabetical list of all authors of items in the FDA.</p>
  <p><strong>Browse by Title</strong> allows you to move through an alphabetical list of all titles of items in the FDA.</p>
  <p><strong>Browse by Subject </strong>allows you to move through an alphabetical list of subjects assigned to items in the FDA.</p>

  </blockquote>
  <hr />

  <td class="leftAlign"><a name="login"></a><strong>  SIGN ON TO FDA </font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
  <p><strong>You may sign on to the system if you wish to:</strong> </p>
  <ul>
    <li>subscribe to a collection and receive e-mail updates when new items are added</li>
    <li>add new content</li>
    <li>edit your profile</li>
    <li>view restricted collections (e.g. some school’s theses and dissertations are only available to active members of the NYU community)</li>

  </ul>
  <table>
  <p>When you access an area
    of the FDA that requires authorization, the system will require you to log in with your NYU netID and password.
    All users can register to become subscribers to public collections. Some restricted functions, such
    as content submission, require authorization from the community.</p>


  <p><strong>My FDA</strong> is a personal
    page that is maintained for each member. This page can contain a list of items
    that are in the submission process for a particular member, or a task list of
    items that need attention such as editing, reviewing, or checking.</p>
  <p><strong>Edit Profile</strong> allows
    you to change your password and change the information we have for you. You must be authenticated with your log-in to change any of your personal information.</p>
  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="search"></a><strong> SEARCH</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>To search all of the FDA, use the the Search option on the top right corner or the search box in the middle of the home page. </p>
  <p> To limit your search to
    a specific community or collection, navigate to that community or collection
    and use the search bar on that page.</p>

  <p>The FDA uses the<strong> Solr/Lucene</strong> search engine. Here are some search hints:</p>
  <blockquote>
    <p>The word(s) you enter in the search box will be searched against each item’s descriptive metadata (including title, author, subject, series, etc.). Additionally, the word(s) you enter will also be searched across the full text of the item itself, if the item has been optimized for optical character recognition (OCR).</p>
    <p><strong>What is not searched
      - Stop Words<br />
      </strong>The<strong> </strong>search engine ignores certain words that occur frequently in
      English, but do not add value to the search. These are: </p>
    <p align="center"> "a", "and"
      , "are" , "as" , "at" , "be" , "but" , "by" , "for" , "if" , "in" , "into",
      </p>
    <p align="center">"is" ,"it"
      ,"no" , "not" , "of" , "on" , "or" , "such", "the" , "to" , "was"</p>

    <p><strong>Truncation<br />
      </strong>Use an asterisk (*) after a word stem to get all hits having words starting
      with that root, for example: </p>
    <blockquote>
      <p> For example:
        Select* will retrieve selects, selector, selectman, selecting. </p>
    </blockquote>
    <p><strong>Stemming <br />
      </strong>The search engine automatically expands words with common endings to include plurals, past tenses, etc.</p>
    <p><strong>Phrase Searching</strong><br />
      To search using multiple words as a phrase, put quotation marks (&quot;) around
      the phrase.</p>
    For example: "organizational change"
    <p><strong>Exact word match</strong><br />
      Put a plus (+) sign before a word if it MUST appear in the search result.
      For instance, in the following search the word &quot;training&quot; is optional,
      but the word &quot;dog&quot; must be in the result. </p>
    <blockquote>
     For example: <b>+dog training</b>
    </blockquote>
    <p><strong>Eliminate items with
      unwanted words<br />
      </strong>Put a minus (-) sign before a word if it should not appear in the search
      results. Alternatively, you can use <strong>NOT</strong>. This can limit your search
      to eliminate unwanted hits.
    <blockquote>
      For example: In the search<b>training -cat</b> or <b>training NOT cat</b> you will get items containing
      the word &quot;training&quot;, except those that also contain the word &quot;cat&quot;.  </blockquote></p>
    <p><strong>Boolean searching</strong></p>
    <p>The following Boolean
      operators can be used to combine terms. Note that they must be CAPITALIZED!</p>
  	<ol>
    <li><p><strong>AND</strong> - to limit
      searches to find items containing all words or phrases combined with this
      operator, e.g.</p>
    <blockquote>
   <b>cats AND dogs</b>
        will retrieve all items that contain BOTH the words &quot;cats&quot; and
        &quot;dogs&quot;.</p>
    </blockquote>
    <li><p><strong>OR</strong> - to enlarge
      searches to find items containing any of the words or phrases surrounding
      this operator </p>
    <blockquote>
      <b>cats OR dogs</b>
        will retrieve all items that contain EITHER the words &quot;cats&quot; or
        &quot;dogs&quot;.</p>
    </blockquote>
    </ol>
    <p>Parentheses can be used
      in the search query to group search terms into sets, and operators can then
      be applied to the whole set.
  	For example:</p>

  </blockquote>
    <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="advanced"></a><strong>  ADVANCED SEARCH</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>The advanced search page
    allows you to specify the fields you wish to search, and to combine these searches
    with the Boolean &quot;and&quot;, &quot;or&quot; or &quot;not&quot;. </p>
  <p>You can restrict your search
    to a community by clicking on the arrow to the right of the top box. If you
    want your search to encompass all of the FDA, leave that box in the default position.</p>
  <p>Enter the phrase you are searching for in the search box. You can further refine the search by specifying what the title, author, subject or date issued should equal, contain, not equal or not contain. </p>
  <p align="center"> <img src= "advanced-search.jpg" width="600" style="border:2px solid black" > </p>



  <p><strong>Note: You must use the
    input boxes in order. If you leave the first one blank your search will not
    work. </strong></p>
  <hr />

  <table>
      <tr>
      <td class="leftAlign"><a name="communities"></a><strong>COMMUNITIES</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>Within each community there can be an unlimited number subcommunities and an unlimited number of collections. Subcommunities and collections correspond to administrative entities such as departments, labs, research centers, and individual researchers. FDA content lives at the collection level, and each collection may contain an unlimited number of items.</p>
  <p>Each community has its own
    entry page displaying information, news and links reflecting the interests of
    that school/college, as well as a descriptive list of collections within the community.</p>
  <p> For the FDA, the the hierarachy of structure is as follows -- NYU school or division --> Collection of faculty member/project --> Individual item.
  <hr />

  <table>
      <tr>
      <td class="leftAlign"><a name="collections"></a><strong>  COLLECTIONS</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>Communities can maintain an unlimited number of collections in the FDA. Collections can be organized around a topic, or by type of information (such as working papers or datasets) or by any other sorting method a community finds useful in organizing its digital
    items. Collections can have different policies and workflows.</p>
  <p>Each FDA collection has its own entry page displaying information, news and links reflecting the interests of users of that collection.</p>
  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="submit"></a><strong>  SUBMIT</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p><strong>Stopping during the Submission
    Process:</strong></p>
  <p>At any point in the submission
    process you can stop and save your work for a later date by clicking on the
    &quot;cancel/save&quot; button at the bottom of the page. The data you have
    already entered will be stored until you come back to the submission, and you
    will be reminded on your &quot;My FDA&quot; page that you have a submission
    in process. If somehow you accidentally exit from the submit process, you can
    always resume from your &quot;My FDA&quot; page. You can also cancel your
    submission at any point. </p>
  <p><strong>Progress Bar - Buttons at Top of Page:</strong></p>
  <p>At the top of the submit
    pages you will find 6 rectangular buttons representing each step in the submission
    process. As you move through the process these buttons will change color. Once
    you have started you can also use these buttons to move back and forth within
    the submission process by clicking on them. You will not lose data by moving
    back and forth. </p>
    <p align="center"> <img src= "progress-bar.jpg" width="700" style="border:2px solid black" > </p>


  <p><strong>Select Collection:</strong></p>
  <p>Click on the arrow at
    the right of the drop-down box to see a list of Collections. Move your mouse
    to the collection into which you wish to add your item and click.</p>
  <p>(If you are denied permission
    to submit to the collection you choose, please contact contact archive.help@nyu.edu
    for more information.)</p>
  <p>You must be authorized by
    a community to submit items to a collection. If you would like to submit an
    item to the FDA, but don't see an appropriate community, please contact contact archive.help@nyu.edu to find out how
    you can get your community set up in FDA. </p>
  <p>Click on the &quot;Next&quot;
    button to proceed, or &quot;Cancel/Save&quot; button to stop and save or cancel
    your submission.</p>
  <hr />

  <table>
      <tr>
      <td class="leftAlign"><a name="describe1"></a><strong>STEP 1: License </strong></td>
      <td class="rightAlign"><a href="#submit">top of submit</a></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p> The FDA requires agreement to this non-exclusive distribution license before your item can appear in the Archive. Please read the license carefully. If you have any questions, please contact archive.help@nyu.edu.

  <p align="center"> <img src= "license.jpg" width="700" style="border:2px solid black" > </p>

  <tr>
      <td class="leftAlign"><a name="describe1"></a><strong>STEP 2: Upload </strong></td>
      <td class="rightAlign"><a href="#submit">top of submit</a></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>


  	<p> There are two ways of uploading the file you want. You can either select the file using the 'Open' option or you can drag and drop the file into the upload window.

     <p align="center"> <img src= "upload.jpg" width="700" style="border:2px solid black" > </p>

  <p>Click on the &quot;next&quot;
    button to proceed, or &quot;cancel/save&quot; button to stop and save or cancel
    your submission. You can also choose 'Skip File Upload' to add the file at a later time. </p>

  <table>
      <tr>
      <td class="leftAlign"><a name="describe2"></a><strong> STEP 3: Describe </strong></td>
      <td class="rightAlign"><a href="#submit">top of submit</a></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p align="center"> <img src= "metadata1.jpg" width="600" style="border:2px solid black" > </p>
  <p> The information you fill
    in on this screen will form the metadata record that will enable users
    to retrieve your item using search engines. The richer the metadata, the more
    &quot;findable&quot; your item will be, so please take the time to fill in as
    many fields as are applicable to your item. The Author, Title and Date of Issue (year) fields are mandatory. </p>
    <p><strong>Author:</strong></p>
    <p> This can be a person,
      organization or service responsible for creating or contributing to the content
      of the item. By clicking on the &quot;Add More&quot; button you can add as
      many authors as needed.&nbsp;&nbsp;</p>
    <p>If the author is an organization, use the last name input box for the organization name. </p>
    <p><strong>Title:</strong> </p>
    <p>Enter the full and proper
      name by which this item should be known. All FDA items must have a title!</p>
    <strong>Other Titles:</strong>
    <p>If your item has a valid
      alternative title, for instance, a title in another language or an abbreviation,
      then enter it here. </p>
    <p><strong>Date of Issue:</strong>
    <p>If your item was previously
      published or made public, enter the date of that event here. If you don't
      know the month, leave the default &quot;no month&quot;; otherwise select a
      month from the drop-down box. If you don't know the exact day, leave that
      box empty.</p>
    <p><strong>Publisher: </strong></p>
    <p>Enter the name of the
      publisher of this item.</p>
    <p><strong>Citation: </strong>
    <p>Enter citation information
      for this item if it was a journal article or part of a larger work, such as
      a book chapter. For <strong>journal articles</strong>, include the journal title, volume
      number, date and paging.<br />
      For <strong>book chapters</strong>, include the book title, place of publication, publisher
      name, date and paging.</p>
    <p><strong>Series/Report No.:</strong></p>
    <p>Some of the collections
      in the FDA are numbered series such as technical reports or working papers.
      If this collection falls into that category, then there should be a default
      value in the <strong>Series</strong><i> </i> <strong>Name</strong> box which you should not change,
      but you will have to fill in the assigned number in the <strong>Report or Paper
      No.</strong> input box. &nbsp </p>
    <p><strong>Identifiers: </strong></p>
    <p>If you know of a unique
      number or code that identifies this item in some system, please enter it here.
      Click on the arrow to the right of the input box, and select from one of the
      choices in the drop down menu. The choices refer to:</p>
  <blockquote>
      <p><strong>Govt.doc # </strong>-
        Government Document Number - e.g. NASA SP 8084<br />
  	  <strong>DOI</strong> - Digital Object Identifier - e.g. 10.10.1038/nphys1170 <br />
        <strong>ISBN</strong> - International Standard Book Number - e.g. 0-1234-5678-9<br />
        <strong>ISSN</strong> - International Standard Serial Number - e.g. 1234-5678<br />
        <strong>ISMN</strong> - International Standard Music Number - e.g. M-53001-001-3<br />
        <strong>URI</strong> - Universal Resource Identifier - e.g.. http://www.dspace.org/help/submit.html<br />
        <strong>Other </strong>- An unique identifier assigned to the item using a system
        other than the above</p>
  	  </blockquote>
    <p><strong>Type: </strong></p>
    <p>Select the type of work
      (or genre) that best fits your item. To select more than one value in the
      list, you may have to hold down the &quot;ctrl&quot; or &quot;shift&quot;
      key. </p>
  <p align="center"> <img src= "metadata2.jpg" width="600" style="border:2px solid black" > </p>


    <p><strong>Language:</strong></p>
    <p align="left">Select the
      language of the intellectual content of your item. If the default (English
      - United States) is not appropriate, click on the arrow on the right of the
      drop down box to see a list of languages commonly used for publications,
      e.g.</p>
    <p>If your item is not a
      text document and language is not applicable as description, then select the
      N/A choice.</p>
  <p><strong>Subject Keywords:</strong></p>
  <p> Please enter as many subject
    keywords as are appropriate to describe this item, from the general to the specific.
    The more words you provide, the more likely it is that users will find this
    item in their searches. Use one input box for each subject word or phrase. You
    can get more input boxes by clicking on the &quot;add more&quot; button. Examples:
    </p>
  <p>Your community may suggest
    the use of a specific vocabulary, taxonomy, or thesaurus. If this is the case,
    please select your subject words from that list.</p>
  <p><strong>Abstract:</strong></p>
  <p>You can either cut and paste
    an abstract into this box, or you can type in the abstract. There is no limit
    to the length of the abstract. We urge you to include an abstract for the convenience
    of end-users and to enhance search and retrieval capabilities.</p>
  <p><strong>Sponsors:</strong></p>
  <p>If your item is the product
    of sponsored research, you can provide information about the sponsor(s) here.
    This is a freeform field where you can enter any note you like.</p>
  <p>&nbsp;</p>
  <p><strong>Description:</strong></p>
  <p>Here you can enter any other
    information describing the item you are submitting or comments that may be of
    interest to users of the item.</p>
    <p><strong>Rights:</strong></p>
  <P> Here you can enter any information about the rights of the use of the item you are submitting. </p>
  <p>Click on the &quot;next&quot;
    button to proceed, or &quot;cancel/save&quot; button to stop and save or cancel
    your submission.</p>
  <table>
   <tr>
      <td class="leftAlign"><a name="verify"></a><strong>STEP 4: Verify Submission</strong></td>
      <td class="rightAlign"><a href="#submit">top of submit</a></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>This page lets you review the information you have entered to describe the item. To correct or edit information, click on the corresponding button on the right, or use the buttons in the progress bar at the top of the page to move around the submission pages. When
    you are satisfied that the submission is in order, click on the &quot;Next&quot; button to continue. </p>
  <p>Click on the &quot;Cancel/Save&quot;
    button to stop and save your data, or to cancel your submission.</p>
    <p align="center"> <img src= "verify-submission.jpg" width="600" style="border:2px solid black" > </p>


  <table>
      <tr>
      <td class="leftAlign"><a name="complete"></a><strong>STEP 5: Complete</strong></td>
      <td class="rightAlign"><a href="#submit">top of submit</a></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>Now that your submission
    has been successfully entered into the FDA, it will go through the
    workflow process designated for the collection to which you are submitting.
    Some collections require the submission to go through editing or review steps,
    while others may immediately accept the submission. You will receive e-mail
    notification as soon as your item has become a part of the collection, or if
    for some reason there is a problem with your submission. If you have questions
    about the workflow procedures for a particular collection, please contact the
    community responsible for the collection directly. You can check on the status
    of your submission by going to the My FDA page.</p>
      <p align="center"> <img src= "complete.jpg" width="700" style="border:2px solid black" > </p>

  <hr />

  <table>
      <tr>
      <td class="leftAlign"><a name="modify"></a><strong>  MODIFY</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>

  <p> Collection administrators have the ability to add content to, modify existing content in, and remove content from their collections.</p>

  <p>Once you have submitted something to your collection, a FDA record is created for the uploaded file. That file and the descriptive information about it (the "metadata") are called an "item." An item in the FDA can have multiple digital files attached to it.
  For example, you may want to store a high-quality image file and a smaller, compressed derivative of it together as a single item.</p>

  <p>To add a new file to an already-existing item in the FDA, browse to the item in your collection you want to add to and click on the 'Open' button. Once the home page of the item opens, select 'Edit' on the left.</p>
  <p>The submission process starting with <strong>Step 1: License</strong> will begin and new files can be added to the item and current files can also be deleted.</p>
  <p>You can also edit or add metadata to any item in your collection after the item has been uploaded. Navigate to the item to be edited and go to <strong>Step 3: Describe</strong> and change the fields of metadata that need to be edited. When finished, click the Update button to save your changes.</p>

  <p><strong>Note:</strong> Please do not delete or modify the original file associated with an FDA item or the License Text. </p>

  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="formats"></a><strong> FILE FORMATS</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>

  <p>The FDA accepts files in a wide range of formats and with sizes upto 2 GB. The FDA maintains a <a href="https://archive.nyu.edu/help/formats.jsp">complete list</a> of formats that it supports.
   Files are archived in the format in which they were uploaded; the FDA does not provide migration of files from one format to another.
  Keep in mind that not all potential viewers may have the means to view certain formats and use file formats that are most commonly used and most appropriate to their content.</p>
  <hr />

  <table>
      <tr>
      <td class="leftAlign"><a name="handles"></a><strong> HANDLES</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>When your item becomes a
    part of the FDA repository it is assigned a persistent URL. This means that,
    unlike most URLs, this identifier will not have to be changed when the system
    migrates to new hardware, or when changes are made to the system. The FDA
    is committed to maintaining the integrity of this identifier
    so that you can safely use it to refer to your item when citing it in publications
    or other communications. Our persistent urls are registered with the <a href="http://www.handle.net/">Handle
    System</a>, a comprehensive system for assigning, managing, and resolving persistent
    identifiers, known as "handles," for digital objects and other resources on
    the Internet. The Handle System is administered by the <a href="http://www.cnri.reston.va.us/">Corporation
    for National Research Initiatives (CNRI)</a>, which undertakes, fosters, and
    promotes research in the public interest.</p>
  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="mydspace"></a><strong>  MY FDA</font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>If you are an authorized
   FDA submitter or supervisor, or if you are a staff member responsible for FDA collection
    or metadata maintenance, you will have a My FDA page. Here you will find:</p>
  <ul>
    <li>a list of your in-progress
      submissions - from this list you can resume the submission process where you
      left off, or you can remove the submission and cancel the item.</li>
    <li>a list of the submissions which you are supervising or collaborating on</li>
    <li>a list of submissions
      that are awaiting your action (if you have a collection workflow role).</li>
    <li>a link to a list of items
      that you have submitted and that have already been accepted into the FDA. </li>
  </ul>
  <p />
  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="subscribe"></a><strong>  RECEIVE EMAIL UPDATES </font></strong></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>Users can subscribe to receive
    daily e-mail alerts of new items added to collections. Users may subscribe to
    as many collections as they wish. To subscribe:</p>
  <ul>
    <li>Navigate to a collection
      for which you would like to receive e-mail alerts, and click on the &quot;Subscribe&quot;
      button on the menu on the right. (repeat for other collections).</li>
    <li>to edit your subscriptions,
      go to the &quot;Receive email updates &quot; page. from the dropdown on the right corner of the home page. </li>
  	<li> To unsubscribe from a collection,  click the Unsubscribe button for the collection you want to unsubscribe from.</li>

  </ul>
  <hr />
  <table>
      <tr>
      <td class="leftAlign"><a name="admin"></a><h3><strong>  FOR FURTHER ASSISTANCE </font></strong></h3></td>
      <td class="rightAlign"><a href="#contents">top</a></td>
      </tr>
  </table>
  <p>For requests and assistance with using the FDA, please contact archive.help@nyu.edu.
  <hr />

>>>>>>> FDA237-create-help-page
     
</dspace:layout>
