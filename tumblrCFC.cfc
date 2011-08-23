<!---
	Name: tumblrCFC
	Author: Andy Matthews
	Website: http://www.andyMatthews.net || http://tumblrCFC.riaforge.org
	Created: 3/12/2010
	Last Updated: 3/12/2010
	History:
		8/18/2011 - Added ColdFusion 7 support (thanks David Wood for the encouragement)
		3/14/2010 - Changed read method name to readBlog.
					Added readDashboard, readLikes, likePost, and unlikePost methods
		3/12/2010 - Initial creation, includes only the read method
	Purpose: CFC allowing users to tap into the Tumblr blog API
	Version: Listed in contructor
--->
<cfcomponent hint="CFC allowing users to tap into the Tumblr blog API" displayname="tumblrCFC" output="false">

	<cfscript>
		VARIABLES.version = '0.2';
		VARIABLES.appName = 'tumblrCFC';
		VARIABLES.lastUpdated = DateFormat(createDate(2010,03,14),'mm/dd/yyyy');
		VARIABLES.acctEmail = '';
		VARIABLES.acctPassword = '';
	</cfscript>

	<!--- housekeeping methods --->
	<cffunction name="init" description="Initializes the CFC, returns itself" displayname="init" returntype="tumblrCFC" hint="Initializes tumblrCFC" access="public" output="false">
		<cfargument name="acctEmail" type="string" required="false">
		<cfargument name="acctPassword" type="string" required="false">

		<cfscript>
			if (StructKeyExists(ARGUMENTS,'acctEmail')) VARIABLES.acctEmail = ARGUMENTS.acctEmail;
			if (StructKeyExists(ARGUMENTS,'acctPassword')) VARIABLES.acctPassword = ARGUMENTS.acctPassword;
		</cfscript>

		<cfreturn THIS>
	</cffunction>

	<cffunction name="currentVersion" description="Returns current version of tumblrCFC" displayname="currentVersion" returntype="string" hint="Reports current version" access="public" output="false">
		<cfreturn VARIABLES.version>
	</cffunction>

	<cffunction name="lastUpdated" description="Returns last updated date" displayname="lastUpdated" returntype="date" hint="Returns last updated date" access="public" output="false">
		<cfreturn VARIABLES.lastUpdated>
	</cffunction>

	<!--- meat and potatos --->
	<cffunction name="readBlog" description="Reading posts as XML or JSON" displayname="readBlog" returntype="struct" access="public" output="false">
		<cfargument name="tumblrUsername" type="string" required="false" default="demo">
		<cfargument name="outputType" type="string" required="false" default="xml" hint="xml or json">
		<cfargument name="start" type="numeric" required="false" default="0" hint="The post offset to start from. The default is 0.">
		<cfargument name="num" type="numeric" required="false" default="20" hint="The number of posts to return. The default is 20, and the maximum is 50.">
		<cfargument name="type" type="string" required="false" hint="Must be one of text, quote, photo, link, chat, video, or audio. Leave unspecified, or empty, for all types">
		<cfargument name="id" type="numeric"  required="false" hint="A specific post ID to return. Use instead of start, num, or type.">
		<cfargument name="filter" type="string" required="false" hint="Allowed values: text - Plain text only. No HTML; none - No post-processing. Output exactly what the author entered.">
		<cfargument name="tagged" type="string" required="false" hint="Return posts with this tag in reverse-chronological order (newest first).">
		<cfargument name="search" type="string" required="false" hint="Search for posts with this query.">
		<cfargument name="includePrivate" type="boolean" required="false" hint="Includes posts marked as private, requires account email and password to be configured in init.">
		<!--- <cfargument name="state" type="string" required="false" hint=""> --->

		<cfscript>
			var LOCAL = StructNew();
			LOCAL.returnStruct = StructNew();

			// required attributes for cfhttp call
			LOCAL.attributes = StructNew();
			LOCAL.attributes.url = 'http://#ARGUMENTS.tumblrUsername#.tumblr.com/api/read';
			if (ARGUMENTS.outputType EQ 'JSON') LOCAL.attributes.url = 'http://#ARGUMENTS.tumblrUsername#.tumblr.com/api/read/json';

			// is this an authenticated read?
			if (StructKeyExists(ARGUMENTS,'includePrivate')) {
				LOCAL.actionType = 'formField';
				LOCAL.attributes.method = 'POST';
			} else {
				LOCAL.actionType = 'URL';
				LOCAL.attributes.method = 'GET';
			}
		</cfscript>
		<cftry>
			<cfhttp method="#LOCAL.attributes.method#" url="#LOCAL.attributes.url#">
			<!---<cfhttp attributecollection="#LOCAL.attributes#">--->
				<!--- if the id argument exists, we don't need start, num, or type --->
				<cfif StructKeyExists(ARGUMENTS,'id')>
					<cfhttpparam name="id" type="#LOCAL.actionType#" value="#ARGUMENTS.id#">
				<cfelse>
					<cfif StructKeyExists(ARGUMENTS,'start')>
						<cfhttpparam name="start" type="#LOCAL.actionType#" value="#ARGUMENTS.start#">
					</cfif>
					<cfif StructKeyExists(ARGUMENTS,'num')>
						<cfif ARGUMENTS.num GT 50>
							<cfset ARGUMENTS.num = 50>
						</cfif>
						<cfhttpparam name="num" type="#LOCAL.actionType#" value="#ARGUMENTS.num#">
					</cfif>
					<cfif StructKeyExists(ARGUMENTS,'type')>
						<!--- make sure the passed string is of the correct type --->
						<cfif ListFindNoCase('text,quote,photo,link,chat,video,audio',ARGUMENTS.type)>
							<cfthrow message="ARGUMENTS.type must be text, quote, photo, link, chat, video, or audio">
						<cfelse>
							<cfhttpparam name="type" type="#LOCAL.actionType#" value="#ARGUMENTS.type#">
						</cfif>
					</cfif>
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'filter')>
					<!--- make sure the passed string is of the correct type --->
					<cfif ListFindNoCase('text,none',ARGUMENTS.filter)>
						<cfthrow message="ARGUMENTS.filter must be either text or none">
					<cfelse>
						<cfhttpparam name="filter" type="#LOCAL.actionType#" value="#ARGUMENTS.filter#">
					</cfif>
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'tagged')>
					<cfhttpparam name="tagged" type="#LOCAL.actionType#" value="#ARGUMENTS.tagged#">
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'search')>
					<cfhttpparam name="search" type="#LOCAL.actionType#" value="#ARGUMENTS.search#">
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'includePrivate') AND VARIABLES.acctEmail IS NOT '' AND VARIABLES.acctPassword IS NOT ''>
					<cfhttpparam name="email" type="#LOCAL.actionType#" value="#VARIABLES.acctEmail#">
					<cfhttpparam name="password" type="#LOCAL.actionType#" value="#VARIABLES.acctPassword#">
				</cfif>
			</cfhttp>

			<!--- set data, success, and message values --->
			<cfif ARGUMENTS.outputType EQ 'JSON'>
				<cfset LOCAL.returnStruct.data = cfhttp.filecontent>
			<cfelse>
				<cfset LOCAL.returnStruct.data = XMLParse(cfhttp.filecontent)>
			</cfif>
			<cfset LOCAL.returnStruct.success = 1>
			<cfset LOCAL.returnStruct.message = 'Request successful'>

			<cfcatch type="any">
				<!--- set success and message value --->
				<cfset LOCAL.returnStruct.data = ''>
				<cfset LOCAL.returnStruct.success = 0>
				<cfset LOCAL.returnStruct.message = 'An error occurred. Please check your parameters and try your requesst again.'>
			</cfcatch>
		</cftry>

		<cfreturn LOCAL.returnStruct>

	</cffunction>

	<cffunction name="readDashboard" description="Reading dashboard posts" displayname="readDashboard" returntype="struct" access="public" output="false">
		<cfargument name="start" type="numeric" required="false" default="0" hint="The post offset to start from. The default is 0.">
		<cfargument name="num" type="numeric" required="false" default="20" hint="The number of posts to return. The default is 20, and the maximum is 50.">
		<cfargument name="filter" type="string" required="false" hint="Allowed values: text - Plain text only. No HTML; none - No post-processing. Output exactly what the author entered.">
		<cfargument name="includeLikes" type="boolean" required="false" hint="1 or 0, default 0. If 1, liked posts will have the liked='true' attribute.">

		<cfscript>
			var LOCAL = StructNew();
			LOCAL.returnStruct = StructNew();

			// required attributes for cfhttp call
			LOCAL.attributes = StructNew();
			LOCAL.attributes.method = 'POST';
			LOCAL.attributes.url = 'http://www.tumblr.com/api/dashboard';
		</cfscript>

		<cftry>
			<cfhttp method="POST" url="http://www.tumblr.com/api/dashboard">
			<!---<cfhttp attributecollection="#LOCAL.attributes#">--->
				<cfif StructKeyExists(ARGUMENTS,'start')>
					<cfif ARGUMENTS.start GT 250>
						<cfset ARGUMENTS.start = 250>
					</cfif>
					<cfhttpparam name="start" type="formField" value="#ARGUMENTS.start#">
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'num')>
					<cfif ARGUMENTS.num GT 50>
						<cfset ARGUMENTS.num = 50>
					</cfif>
					<cfhttpparam name="num" type="formField" value="#ARGUMENTS.num#">
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'filter')>
					<!--- make sure the passed string is of the correct type --->
					<cfif ListFindNoCase('text,none',ARGUMENTS.filter)>
						<cfthrow message="ARGUMENTS.filter must be either text or none">
					<cfelse>
						<cfhttpparam name="filter" type="formField" value="#ARGUMENTS.filter#">
					</cfif>
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'includeLikes')>
					<cfhttpparam name="likes" type="formField" value="#ARGUMENTS.likes#">
				</cfif>
				<cfif VARIABLES.acctEmail IS NOT '' AND VARIABLES.acctPassword IS NOT ''>
					<cfhttpparam name="email" type="formField" value="#VARIABLES.acctEmail#">
					<cfhttpparam name="password" type="formField" value="#VARIABLES.acctPassword#">
				</cfif>
			</cfhttp>

			<!--- set data, success, and message values --->
			<cfset LOCAL.returnStruct.data = XMLParse(cfhttp.filecontent)>
			<cfset LOCAL.returnStruct.success = 1>
			<cfset LOCAL.returnStruct.message = 'Request successful'>

			<cfcatch type="any">
				<!--- set success and message value --->
				<cfset LOCAL.returnStruct.data = ''>
				<cfset LOCAL.returnStruct.success = 0>
				<cfset LOCAL.returnStruct.message = 'An error occurred. Please check your parameters and try your requesst again.'>
			</cfcatch>
		</cftry>

		<cfreturn LOCAL.returnStruct>

	</cffunction>

	<cffunction name="readLikes" description="Reading liked posts" displayname="readLikes" returntype="struct" access="public" output="false">
		<cfargument name="start" type="numeric" required="false" default="0" hint="The post offset to start from. The default is 0.">
		<cfargument name="num" type="numeric" required="false" default="20" hint="The number of posts to return. The default is 20, and the maximum is 50.">
		<cfargument name="filter" type="string" required="false" hint="Allowed values: text - Plain text only. No HTML; none - No post-processing. Output exactly what the author entered.">

		<cfscript>
			var LOCAL = StructNew();
			LOCAL.returnStruct = StructNew();

			// required attributes for cfhttp call
			LOCAL.attributes = StructNew();
			LOCAL.attributes.method = 'POST';
			LOCAL.attributes.url = 'http://www.tumblr.com/api/likes';
		</cfscript>

		<cftry>
			<cfhttp method="POST" url="http://www.tumblr.com/api/likes">
			<!---<cfhttp attributecollection="#LOCAL.attributes#">--->
				<cfif StructKeyExists(ARGUMENTS,'start')>
					<cfif ARGUMENTS.start GT 1000>
						<cfset ARGUMENTS.start = 1000>
					</cfif>
					<cfhttpparam name="start" type="formField" value="#ARGUMENTS.start#">
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'num')>
					<cfif ARGUMENTS.num GT 50>
						<cfset ARGUMENTS.num = 50>
					</cfif>
					<cfhttpparam name="num" type="formField" value="#ARGUMENTS.num#">
				</cfif>
				<cfif StructKeyExists(ARGUMENTS,'filter')>
					<!--- make sure the passed string is of the correct type --->
					<cfif ListFindNoCase('text,none',ARGUMENTS.filter)>
						<cfthrow message="ARGUMENTS.filter must be either text or none">
					<cfelse>
						<cfhttpparam name="filter" type="formField" value="#ARGUMENTS.filter#">
					</cfif>
				</cfif>
				<cfif VARIABLES.acctEmail IS NOT '' AND VARIABLES.acctPassword IS NOT ''>
					<cfhttpparam name="email" type="formField" value="#VARIABLES.acctEmail#">
					<cfhttpparam name="password" type="formField" value="#VARIABLES.acctPassword#">
				</cfif>
			</cfhttp>

			<!--- set data, success, and message values --->
			<cfset LOCAL.returnStruct.data = XMLParse(cfhttp.filecontent)>
			<cfset LOCAL.returnStruct.success = 1>
			<cfset LOCAL.returnStruct.message = 'Request successful'>

			<cfcatch type="any">
				<!--- set success and message value --->
				<cfset LOCAL.returnStruct.data = ''>
				<cfset LOCAL.returnStruct.success = 0>
				<cfset LOCAL.returnStruct.message = 'An error occurred. Please check your parameters and try your requesst again.'>
			</cfcatch>
		</cftry>

		<cfreturn LOCAL.returnStruct>

	</cffunction>

	<cffunction name="likePost" description="Liking a post" displayname="likePost" returntype="struct" access="public" output="false">
		<cfargument name="postid" type="numeric" required="false" hint="The numeric post ID to like">
		<cfargument name="reblogkey" type="string" required="false" hint="The reblog-key value for the specified post from its XML as returned by /api/read or /api/dashboard">

		<cfscript>
			var LOCAL = StructNew();
			LOCAL.returnStruct = StructNew();

			// required attributes for cfhttp call
			LOCAL.attributes = StructNew();
			LOCAL.attributes.method = 'POST';
			LOCAL.attributes.url = 'http://www.tumblr.com/api/like';
		</cfscript>

		<cftry>
			<cfhttp method="POST" url="http://www.tumblr.com/api/like">
			<!---<cfhttp attributecollection="#LOCAL.attributes#">--->
				<cfhttpparam name="email" type="formField" value="#VARIABLES.acctEmail#">
				<cfhttpparam name="password" type="formField" value="#VARIABLES.acctPassword#">
				<cfhttpparam name="post-id" type="formField" value="#ARGUMENTS.postid#">
				<cfhttpparam name="reblog-key" type="formField" value="#ARGUMENTS.reblogkey#">
			</cfhttp>

			<!--- set data, success, and message values --->
			<cfset LOCAL.returnStruct.data = cfhttp.filecontent>
			<cfset LOCAL.returnStruct.success = 1>
			<cfset LOCAL.returnStruct.message = 'Request successful'>

			<cfcatch type="any">
				<!--- set success and message value --->
				<cfset LOCAL.returnStruct.data = ''>
				<cfset LOCAL.returnStruct.success = 0>
				<cfset LOCAL.returnStruct.message = 'An error occurred. Please check your parameters and try your requesst again.'>
			</cfcatch>
		</cftry>

		<cfreturn LOCAL.returnStruct>

	</cffunction>

	<cffunction name="unlikePost" description="Unliking a post" displayname="unlikePost" returntype="struct" access="public" output="false">
		<cfargument name="postid" type="numeric" required="false" hint="The numeric post ID to unlike">
		<cfargument name="reblogkey" type="string" required="false" hint="The reblog-key value for the specified post from its XML as returned by /api/read or /api/dashboard">

		<cfscript>
			var LOCAL = StructNew();
			LOCAL.returnStruct = StructNew();

			// required attributes for cfhttp call
			LOCAL.attributes = StructNew();
			LOCAL.attributes.method = 'POST';
			LOCAL.attributes.url = 'http://www.tumblr.com/api/unlike';
		</cfscript>

		<cftry>
			<cfhttp method="POST" url="http://www.tumblr.com/api/unlike">
			<!---<cfhttp attributecollection="#LOCAL.attributes#">--->
				<cfhttpparam name="email" type="formField" value="#VARIABLES.acctEmail#">
				<cfhttpparam name="password" type="formField" value="#VARIABLES.acctPassword#">
				<cfhttpparam name="post-id" type="formField" value="#ARGUMENTS.postid#">
				<cfhttpparam name="reblog-key" type="formField" value="#ARGUMENTS.reblogkey#">
			</cfhttp>

			<!--- set data, success, and message values --->
			<cfset LOCAL.returnStruct.data = cfhttp.filecontent>
			<cfset LOCAL.returnStruct.success = 1>
			<cfset LOCAL.returnStruct.message = 'Request successful'>

			<cfcatch type="any">
				<!--- set success and message value --->
				<cfset LOCAL.returnStruct.data = ''>
				<cfset LOCAL.returnStruct.success = 0>
				<cfset LOCAL.returnStruct.message = 'An error occurred. Please check your parameters and try your requesst again.'>
			</cfcatch>
		</cftry>

		<cfreturn LOCAL.returnStruct>

	</cffunction>
</cfcomponent>