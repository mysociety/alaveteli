# lib/public_body_categories.rb:
# Categorisations of public bodies.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body_categories.rb,v 1.1 2009-09-14 14:45:48 francis Exp $

module PublicBodyCategories

    CATEGORIES_WITH_HEADINGS = [
        "Miscellaneous sr",
            [ "other", "Miscellaneous", "miscellaneous" ],
        _("Central government"),
            [ "department", "Ministerial departments", "a ministerial department" ], 
            [ "non_ministerial_department", "Non-ministerial departments", "a non-ministerial department" ], 
            [ "executive_agency", "Executive agencies", "an executive agency" ], 
            [ "government_office", "Government offices for the regions", "a government office for the regions" ],  
            [ "advisory_committee", "Advisory committees", "an advisory committee" ],
            [ "awc", "Agricultural wages committees", "an agriculatural wages committee" ],
            [ "adhac", "Agricultural dwelling house advisory committees", "an agriculatural dwelling house advisory committee" ],
            [ "newdeal", "New Deal for Communities partnership", "a New Deal for Communities partnership" ],
        "Local and regional",
            [ "local_council", "Local councils", "a local council" ],
            [ "parish_council", "Town and Parish councils", "a town or parish council"], 
            [ "housing_association", "Housing associations", "a housing association"],
            [ "almo", "Housing ALMOs", "a housing ALMO"],
            [ "municipal_bank", "Municipal bank", "a municipal bank"],
            [ "nsbody", "North/south bodies", "a north/south body"],
            [ "pbo", "Professional buying organisations", "a professional buying organisation"],
            [ "regional_assembly", "Regional assemblies", "a regional assembly"], 
            [ "rda", "Regional development agencies", "a regional development agency" ], 
        "Education",
            [ "university", "Universities", "a university" ],
            [ "university_college", "University colleges", "a university college" ], 
            [ "cambridge_college", "Cambridge colleges", "a Cambridge college" ],
            [ "durham_college", "Durham colleges", "a Durham college" ],
            [ "oxford_college", "Oxford colleges", "an Oxford college or permanent private hall" ],
            [ "york_college", "York colleges", "a college of the University of York" ],
            [ "university_owned_company", "University owned companies", "a university owned company" ],
            [ "hei", "Higher education institutions", "a higher educational institution" ],
            [ "fei", "Further education institutions", "a further educational institution" ],
            [ "school", "Schools", "a school" ],
            [ "research_council", "Research councils", "a research council" ],
            [ "lib_board", "Education and library boards", "an education and library board" ],
            [ "rbc", "Regional Broadband Consortia", "a Regional Broadband Consortium" ],
        "Environment",
            [ "npa", "National park authorities", "a national park authority" ], 
            [ "rpa", "Regional park authorities", "a regional park authority" ],
            [ "sea_fishery_committee", "Sea fisheries committees", "a sea fisheries committee" ], 
            [ "watercompanies", "Water companies", "a water company" ],
            [ "idb", "Internal drainage boards", "an internal drainage board" ],
            [ "rfdc", "Regional flood defence committees", "a regional flood defence committee" ],
            [ "wda", "Waste disposal authorities", "a waste disposal authority" ],
            [ "zoo", "Zoos", "a zoo" ],
        "Health",
            [ "nhstrust", "NHS trusts", "an NHS trust" ],
            [ "pct", "Primary care trusts", "a primary care trust" ],
            [ "nhswales", "NHS in Wales", "part of the NHS in Wales" ],
            [ "nhsni", "NHS in Northern Ireland", "part of the NHS in Northern Ireland" ],
            [ "hscr", "Health / social care", "Relating to health / social care" ],
            [ "pha", "Port health authorities", "a port health authority"],
            [ "sha", "Strategic health authorities", "a strategic health authority" ],
            [ "specialha", "Special health authorities", "a special health authority" ],
        "Media and culture",
            [ "media", "Media", "a media organisation" ],
            [ "rcc", "Cultural consortia", "a cultural consortium"],
            [ "museum", "Museums and galleries", "a museum or gallery" ],
        "Military and security services",
            [ "military_college", "Military colleges", "a military college" ],
            [ "security_services", "Security services", "a security services body" ],
        "Emergency services and the courts",
            [ "police", "Police forces", "a police force" ], 
            [ "police_authority", "Police authorities", "a police authority" ], 
            [ "dpp", "District policing partnerships", "a district policing partnership" ],
            [ "fire_service", "Fire and rescue services", "a fire and rescue service" ],
            [ "prob_board", "Probation boards", "a probation board" ],
            [ "rules_committee", "Rules commitees", "a rules committee" ],
            [ "tribunal", "Tribunals", "a tribunal"],
        "Transport",
            [ "npte", "Passenger transport executives", "a passenger transport executive" ],
            [ "port_authority", "Port authorities", "a port authority" ],
            [ "scp", "Safety Camera Partnerships", "a safety camera partnership" ],
            [ "srp", "Safer Roads Partnership", "a safer roads partnership" ]
    ]

    # Arranged in different ways for different sorts of displaying
    CATEGORIES_WITH_DESCRIPTION = CATEGORIES_WITH_HEADINGS.select() { |a| a.instance_of?(Array) } 
    CATEGORIES = CATEGORIES_WITH_DESCRIPTION.map() { |a| a[0] }
    CATEGORIES_BY_TAG = Hash[*CATEGORIES_WITH_DESCRIPTION.map() { |a| a[0..1] }.flatten]
    CATEGORY_SINGULAR_BY_TAG = Hash[*CATEGORIES_WITH_DESCRIPTION.map() { |a| [a[0],a[2]] }.flatten]
end

