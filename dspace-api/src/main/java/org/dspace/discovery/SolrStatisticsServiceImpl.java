package org.dspace.discovery;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.collections.MapUtils;
import org.apache.commons.collections.Transformer;
import org.apache.commons.lang.ArrayUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.time.DateFormatUtils;
import org.apache.commons.validator.routines.UrlValidator;
import org.apache.http.HttpHost;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.params.ClientPNames;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.log4j.Logger;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.request.AbstractUpdateRequest;
import org.apache.solr.client.solrj.request.ContentStreamUpdateRequest;
import org.apache.solr.client.solrj.response.FacetField;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.client.solrj.util.ClientUtils;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.SolrInputDocument;
import org.apache.solr.common.params.*;
import org.apache.solr.common.util.NamedList;
import org.apache.solr.handler.extraction.ExtractingParams;
import org.dspace.content.*;
import org.dspace.content.Collection;
import org.dspace.content.authority.ChoiceAuthorityManager;
import org.dspace.content.authority.Choices;
import org.dspace.content.authority.MetadataAuthorityManager;
import org.dspace.core.*;
import org.dspace.discovery.configuration.*;
import org.dspace.handle.HandleManager;
import org.dspace.storage.rdbms.DatabaseUtils;
import org.dspace.util.MultiFormatDateParser;
import org.dspace.utils.DSpace;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Created by katepechekhonova on 2/2/16.
 */
public class SolrStatisticsServiceImpl  extends SolrServiceImpl {

    private HttpSolrServer solr = null;

    private static final Logger log = Logger.getLogger(SolrStatisticsServiceImpl.class);

    protected HttpSolrServer getSolr() {

        if (solr == null) {
            //String solrService = new DSpace().getConfigurationService().getProperty("dspace.base.url")+"/solr/statistics";
            String solrService="http://localhost:8080/solr/statistics";
            UrlValidator urlValidator = new UrlValidator(UrlValidator.ALLOW_LOCAL_URLS);
            if (urlValidator.isValid(solrService) || ConfigurationManager.getBooleanProperty("discovery", "solr.url.validation.enabled", true)) {
                try {
                    log.debug("Solr URL: " + solrService);
                    solr = new HttpSolrServer(solrService);

                    solr.setBaseURL(solrService);
                    solr.setUseMultiPartPost(true);


                } catch (Exception e) {
                    log.error("Error while initializing solr server", e);
                }
            } else {
                log.error("Error while initializing solr, invalid url: " + solrService);
            }
        }

        return solr;
    }

    protected SolrQuery resolveToSolrQuery(Context context, DiscoverQuery discoveryQuery, boolean includeUnDiscoverable)
    {
        SolrQuery solrQuery = new SolrQuery();

        String query = "*:*";
        if(discoveryQuery.getQuery() != null)
        {
            query = discoveryQuery.getQuery();
        }

        solrQuery.setQuery(query);

        return solrQuery;
    }


    protected static DSpaceObject findDSpaceObject(Context context, SolrDocument doc) throws SQLException {

        Integer type = (Integer) doc.getFirstValue(RESOURCE_TYPE_FIELD);
        Integer id = (Integer) doc.getFirstValue(RESOURCE_ID_FIELD);


        if (type != null && id != null)
        {
            return DSpaceObject.find(context, type, id);
        }

        return null;
    }

}
