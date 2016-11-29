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

    protected HttpSolrServer solr = null;

    private static final Logger log = Logger.getLogger(SolrStatisticsServiceImpl.class);

    protected static final String RESOURCE_TYPE_FIELD = "type";
    protected static final String RESOURCE_ID_FIELD = "id";

    public static final String FILTER_SEPARATOR = "\n|||\n";


    protected HttpSolrServer getSolr() {

        if (solr == null) {
            String solrService = new DSpace().getConfigurationService().getProperty("solr-statistics.server");

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

    protected SolrQuery resolveToSolrQuery(Context context, DiscoverQuery discoveryQuery, boolean includeUnDiscoverable) {
        SolrQuery solrQuery = new SolrQuery();

        String query = "*:*";
        if (discoveryQuery.getQuery() != null) {
            query = discoveryQuery.getQuery();
        }

        solrQuery.setQuery(query);

        // Add any search fields to our query. This is the limited list
        // of fields that will be returned in the solr result
        for (String fieldName : discoveryQuery.getSearchFields()) {
            solrQuery.addField(fieldName);
        }
        solrQuery.addField(RESOURCE_TYPE_FIELD);
        solrQuery.addField(RESOURCE_ID_FIELD);


        for (int i = 0; i < discoveryQuery.getFilterQueries().size(); i++) {
            String filterQuery = discoveryQuery.getFilterQueries().get(i);
            solrQuery.addFilterQuery(filterQuery);
        }
        if (discoveryQuery.getDSpaceObjectFilter() != -1) {
            solrQuery.addFilterQuery(RESOURCE_TYPE_FIELD + ":" + discoveryQuery.getDSpaceObjectFilter());
        }


        if (discoveryQuery.getStart() != -1) {
            solrQuery.setStart(discoveryQuery.getStart());
        }

        if (discoveryQuery.getMaxResults() != -1) {
            solrQuery.setRows(discoveryQuery.getMaxResults());
        }

        if (discoveryQuery.getSortField() != null) {
            SolrQuery.ORDER order = SolrQuery.ORDER.asc;
            if (discoveryQuery.getSortOrder().equals(DiscoverQuery.SORT_ORDER.desc))
                order = SolrQuery.ORDER.desc;

            solrQuery.addSortField(discoveryQuery.getSortField(), order);
        }

        for (String property : discoveryQuery.getProperties().keySet()) {
            List<String> values = discoveryQuery.getProperties().get(property);
            solrQuery.add(property, values.toArray(new String[values.size()]));
        }

        List<DiscoverFacetField> facetFields = discoveryQuery.getFacetFields();
        if (0 < facetFields.size()) {
            //Only add facet information if there are any facets

            for (DiscoverFacetField facetFieldConfig : facetFields) {
                String field = transformFacetField(facetFieldConfig, facetFieldConfig.getField(), false);
                solrQuery.addFacetField(field);

                // Setting the facet limit in this fashion ensures that each facet can have its own max
                solrQuery.add("f." + field + "." + FacetParams.FACET_LIMIT, String.valueOf(facetFieldConfig.getLimit()));
                String facetSort;
                if (DiscoveryConfigurationParameters.SORT.COUNT.equals(facetFieldConfig.getSortOrder())) {
                    facetSort = FacetParams.FACET_SORT_COUNT;
                } else {
                    facetSort = FacetParams.FACET_SORT_INDEX;
                }
                solrQuery.add("f." + field + "." + FacetParams.FACET_SORT, facetSort);

            }

            List<String> facetQueries = discoveryQuery.getFacetQueries();
            for (String facetQuery : facetQueries) {
                solrQuery.addFacetQuery(facetQuery);
            }

            if (discoveryQuery.getFacetMinCount() != -1) {
                solrQuery.setFacetMinCount(discoveryQuery.getFacetMinCount());
            }

        }

        return solrQuery;
    }


    protected static DSpaceObject findDSpaceObject(Context context, SolrDocument doc) throws SQLException {

        Integer type = (Integer) doc.getFirstValue(RESOURCE_TYPE_FIELD);
        Integer id = (Integer) doc.getFirstValue(RESOURCE_ID_FIELD);

        if (type != null && id != null) {
            return DSpaceObject.find(context, type, id);
        }

        return null;
    }


    public List<DSpaceObject> search(Context context, String query, String orderfield, boolean ascending, int offset, int max, String... filterquery) {

        try {
            if (getSolr() == null) {
                return Collections.emptyList();
            }

            SolrQuery solrQuery = new SolrQuery();
            solrQuery.setQuery(query);
            //Only return obj identifier fields in result doc
            solrQuery.setFields(RESOURCE_ID_FIELD, RESOURCE_TYPE_FIELD);
            solrQuery.setStart(offset);
            solrQuery.setRows(max);
            if (orderfield != null) {
                solrQuery.setSortField(orderfield, ascending ? SolrQuery.ORDER.asc : SolrQuery.ORDER.desc);
            }
            if (filterquery != null) {
                solrQuery.addFilterQuery(filterquery);
            }
            QueryResponse rsp = getSolr().query(solrQuery);
            SolrDocumentList docs = rsp.getResults();

            Iterator iter = docs.iterator();
            List<DSpaceObject> result = new ArrayList<DSpaceObject>();
            while (iter.hasNext()) {
                SolrDocument doc = (SolrDocument) iter.next();

                DSpaceObject o = DSpaceObject.find(context, (Integer) doc.getFirstValue(RESOURCE_TYPE_FIELD), (Integer) doc.getFirstValue(RESOURCE_ID_FIELD));

                if (o != null) {
                    result.add(o);
                }
            }
            return result;
        } catch (Exception e) {
            // Any acception that we get ignore it.
            // We do NOT want any crashed to shown by the user
            log.error(LogManager.getHeader(context, "Error while quering solr", "Queyr: " + query), e);
            return new ArrayList<DSpaceObject>(0);
        }
    }

}