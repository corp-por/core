-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- this is intended to be overridden by a script attached to a player
templateListCategory = ""
templateListCategoryIndex = 1
templateListFilter = ""

function GetCategoryList()
	local allCats = GetTemplateCategories()
	table.insert(allCats,1,"All")
	return allCats
end

function GetTemplateList()
	local templateListTable = nil

	if(templateListCategory == "All") then
		templatesListTable = GetAllTemplateNames()
	else
		templatesListTable = GetAllTemplateNames(templateListCategory)
	end

	if(templateListFilter ~= nil and templateListFilter ~= "") then
		local fullList = templatesListTable
		templatesListTable = {}
		for i,v in pairs(fullList) do
			if(v:match(templateListFilter)) then
				table.insert(templatesListTable,v)
			end
		end
	end

	table.sort(templatesListTable)

	return templatesListTable
end

-- the window is passed in so the window overriding it can add additional buttons
function AddSelectCategory(dynWindow,startY,categoryList)
	categoryList = categoryList or GetCategoryList()

	dynWindow:AddImage(80,startY+12,"TitleBackground",250,20,"Sliced")
	dynWindow:AddButton(80,startY+16,"CatLeft:","",0,0,"","",false,"Previous")
	dynWindow:AddLabel(210,startY+15,"Select Category",400,0,18,"center")
	dynWindow:AddButton(330,startY+16,"CatRight:","",0,0,"","",false,"Next")

	local scrollWindow = ScrollWindow(20,startY+60,380,480,40)

	for i=1,#categoryList do	
		local scrollElement = ScrollElement()	
		scrollElement:AddButton(0,0, "category:"..categoryList[i],categoryList[i], 350, 40, "", "", false, "List")
		scrollWindow:Add(scrollElement)
	end
	
	dynWindow:AddScrollWindow(scrollWindow)
end

function AddSelectTemplate(dynWindow,startY,closeOnSelect,templateList,categoryList)
	templateList = templateList or GetTemplateList()
	categoryList = categoryList or GetCategoryList()

	if(templateListCategory == "" and #categoryList > 1) then
		templateListCategoryIndex = 0
		ShowSelectCategory()
		return
	elseif(#categoryList == 1) then
		templateListCategory = categoryList[1]
		templateListCategoryIndex = 1
	elseif(templateListCategory == "") then
		DebugMessage("No categories")
		return
	end

	dynWindow:AddImage(40,startY+12,"TitleBackground",250,20,"Sliced")
	dynWindow:AddButton(30,startY+16,"CatLeft:","",0,0,"","",false,"Previous")
	dynWindow:AddLabel(160,startY+15,templateListCategory,340,0,18,"center")
	dynWindow:AddButton(280,startY+16,"CatRight:","",0,0,"","",false,"Next")
	dynWindow:AddButton(310, startY+8, "SelectCat:", "Back", 100, 0, "", "", false, "")	

	local scrollWindow = ScrollWindow(20,startY+60,380,480,40)

	for i=1,#templateList do	
		local scrollElement = ScrollElement()	
		scrollElement:AddButton(0,0, "select:"..templateList[i],templateList[i], 350, 40, "", "", closeOnSelect, "List")
		scrollWindow:Add(scrollElement)
	end

	dynWindow:AddScrollWindow(scrollWindow)
end

function HandleCategoryButtons(action,arg,categoryList)
	categoryList = categoryList or GetCategoryList()

	if(action == "category") then
		templateListCategory = arg
		templateListCategoryIndex = IndexOf(categoryList,arg)
		return true
	elseif(action == "CatLeft") then
		templateListCategoryIndex = ((templateListCategoryIndex - 2) % #categoryList) + 1
		templateListCategory = categoryList[templateListCategoryIndex]
		return true
	elseif( action == "CatRight") then
		templateListCategoryIndex = (templateListCategoryIndex % #categoryList) + 1
		templateListCategory = categoryList[templateListCategoryIndex]
		return true
	elseif( action == "SelectCat" ) then
		templateListCategoryIndex = 0
		templateListCategory = ""
		return true
	end

	return false
end