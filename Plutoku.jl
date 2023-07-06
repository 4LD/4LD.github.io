### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ abde0001-0011-0001-0011-0001dabe0011
begin 
	# @bind bindJSudoku Sudini # et son javascript est inclus au plus haut
	# stylélàbasavecbonus! ## voir juste dans la cellule #Bonus au dessus ↑
	const plutôtvoir = false # true # Plutôt voir l'interface de Pluto.jl (true voir)
	const àcorriger = "😜 Merci de corriger le Sudoku", md"""###### 😜 Merci de revoir le Sudoku modifiable, il n'est pas conforme : 
		En effet, il doit y avoir **un chiffre en double** au moins sur une ligne ou colonne ou carré 😄"""
	const impossible = "🧐 Sudoku faux et impossible", md"""###### 🧐 Sudoku faux et impossible à résoudre :
		Si ce n'est pas le cas, revérifier le Sudoku modifiable, car celui-ci n'a pas de solution"""
	toutestbienquifinitbien(mS, nbChoixfait, nbToursTotal) = matriceàlisteJS(mS), md"**Statistiques :** ce programme fait **$nbChoixfait choix** et _$nbToursTotal $((nbToursTotal>1) ? :tours : :tour)_ pour résoudre ce sudoku"
	const footix = "document.getElementById(\"tesfoot\")?.dispatchEvent(new Event(\"click\"))"
	
	const set19 = Set(1:9) # Pour ne pas le recalculer à chaque fois
	const cool = html"<span id='BN' style='user-select: none;'>😎</span>"
	jsvd() = fill(fill(0,9),9) # JSvide ou JCVD ^^ pseudo const
	adini() = [[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,1,2,3,4,5,0,0,0],[0,2,0,0,3,0,6,0,0],[0,3,4,5,6,0,0,7,0],[0,6,0,0,7,0,8,0,0],[0,7,0,0,8,9,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]] # Sudoku avec deux lettres… 
	using Random: shuffle! # Astuce pour être encore plus rapide = Fast & Furious
	## shuffle!(x) = x ## Si besoin, mais… Everyday I shuffling ! (dixit LMFAO)
	
	struct BondJamesBond # BondDefault(element, default) ## pour Base.get() et @bind
		oo7 # element 	 		## Bond (à binder)
		vodkaMartini # default 	## un défaut ^^
	end # from https://github.com/fonsp/pluto-on-binder/pull/11
	Base.show(io::IO, m::MIME"text/html", bd::BondJamesBond) = 
		Base.show(io,m, bd.oo7)
	Base.get(bd::BondJamesBond) = bd.vodkaMartini # évite Doctor No(thing ou missing)

	SudokuMémo = pushfirst!(repeat([adini()], 3), jsvd()) # garder mes initial(e)s ^^
	listeJSàmatrice(JSudoku::Vector{Vector{Int}}) = hcat(JSudoku...) #' en pinaillant
		jsm = listeJSàmatrice ## mini version
	matriceàlisteJS(mat,d=9) = [mat[:,i] for i in 1:d] #I will be back! ## mat3 aussi
		mjs = matriceàlisteJS ## mini version
	### matriceàlisteJS(listeJSàmatrice(JSudoku)) == JSudoku ## Et inversement
	# nbcm(mat) = count(>(0), mat ) # Nombre de chiffres > 0 dans une matrice
	# nbcj(ljs) = count(>(0), listeJSàmatrice(ljs) ) # idem pour une liste JS
	kelcarré(i::Int,j::Int) = 1+ 3*div(i-1,3) + div(j-1,3) # n° du carré du sudoku
	carré(i::Int,j::Int)= 1+div(i-1,3)*3:3+div(i-1,3)*3, 1+div(j-1,3)*3:3+div(j-1,3)*3 # permet de fabriquer les filtres pour ne regarder qu'un seul carré
	carr(i::Int)= 1+div(i-1,3)*3:3+div(i-1,3)*3 # filtre carré à moiti    é !
	vues(mat::Array{Int,2},i::Int,j::Int)= (view(mat,i,:), view(mat,:,j), view(mat,carr(i),carr(j)) ) # liste chiffres possibles par lignes/colonnes/carrés
	listecarré(mat::Array{Int,2})= [view(mat,carr(i),carr(j)) for i in 1:3:9 for j in 1:3:9] # La liste de tous les carrés du sudoku
	tuplecarré(ii::UnitRange{Int},jj::UnitRange{Int} #=,setij::Set{Tuple{Int,Int}}=#)= [(i,j) for i in ii, j in jj] #if (i,j) ∉ setij]
	simplechiffrePossible(mat::Array{Int,2},i::Int,j::Int)= setdiff(set19,view(mat,i,:), view(mat,:,j), view(mat,carr(i),carr(j))) # case i,j
	### setdiff(set19,vues(mat,i,j)...) # Pour une case en i,j
	chiffrePossible(mat::Array{Int,2},i::Int,j::Int,limp::Set{Int}, ii=carr(i)::UnitRange{Int}, jj=carr(j)::UnitRange{Int})= setdiff(set19,limp,view(mat,i,:), view(mat,:,j), view(mat, ii,jj)) # Plus fin

	function vérifSudokuBon(mat::Array{Int,2}) # Vérifie si le sudoku est réglo
		lescarrés = listecarré(mat)
		for x in 1:9 # Pour tous les chiffres de 1 à 9…
			for i in 1:9 # …est-il en doublon dans une ligne ou une colonne ?
				if count(==(x), mat[i,:])>1 || count(==(x), mat[:,i])>1
					return false
				end
			end
			for c in lescarrés # …est-il en doublon dans un carré ?
				if count(==(x), c)>1
					return false
				end
			end
		end
		return true # Le sudoku semble conforme (mais il peut être impossible)
	end 
	function sac!(n::Int, l::Int, k::Int, ii::UnitRange{Int}, jj::UnitRange{Int}, listepossibles::Set{Int}, fusibles::Dict{Int, Set{Int}}, dico::Dict{Int,Dict{Int,Int}}, dilo::Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}} }}, diko::Dict{Int,Dict{Int,Int}}) # compte l'occurence d'un chiffre pour… (uniclk!)
	 # pour ligne et colonne
	 get!(dico, n, Dict{Int,Int}() ) # dico : posibilités par colonne/ligne
	 get!(dilo, n, Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}} }() ) # dilo : ligne/colonne ♻
	 get!(diko, n, Dict{Int,Int}() ) # diko : carré qui devra suppr. la possibilité
	 get!(fusibles, n, Set{Int}() ) # fusibles : n° déjà grillés
	 for ne in setdiff(listepossibles,fusibles[n]) #
		dico[n][ne] = get(dico[n], ne, 0) + 1
		if dico[n][ne] == 1 
			diko[n][ne] = k 
			dilo[n][ne] = (l, ii, jj)
		elseif dico[n][ne] > 3 || diko[n][ne] != k 
			push!(fusibles[n], ne) 
			delete!(dico[n], ne) 
		end
	 end
	end
	function sak!(i::Int, j::Int, k::Int, ii::UnitRange{Int}, jj::UnitRange{Int}, listepossibles::Set{Int}, fusibles::Dict{Int, Set{Int}}, dilo::Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int}} }}, dico::Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int}} }}, diko::Dict{Int,Dict{Int,Int}}) 
	 # idem pour les karrés ;)
	 get!(diko, k, Dict{Int,Int}() ) # diko : possibilité par karré
	 get!(dico, k, Dict{Int,Tuple{Int,UnitRange{Int}} }() ) # dico : colonne ♻
	 get!(dilo, k, Dict{Int,Tuple{Int,UnitRange{Int}} }() ) # dilo : ligne ♻
	 get!(fusibles, k, Set{Int}() ) # fusibles : n° déjà grillés
	 for ne in setdiff(listepossibles,fusibles[k]) #
		diko[k][ne] = get(diko[k], ne, 0) + 1
		if diko[k][ne] == 1 
			dico[k][ne] = (j, ii)
			dilo[k][ne] = (i, jj)
		elseif diko[k][ne] > 3 || (dico[k][ne][1] != j && dilo[k][ne][1] != i)
			push!(fusibles[k], ne) 
			delete!(diko[k], ne) 
		elseif dico[k][ne][1] != j
			dico[k][ne] = (0 , 0:0) # pas pour la colonne
		elseif dilo[k][ne][1] != i
			dilo[k][ne] = (0 , 0:0) # pas pour la ligne
		end
	 end
	end
	function uniclk!(diclo::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}} ,dicco::Dict{Int, Dict{Int,Int}}, dicko::Dict{Int, Dict{Int,Int}}, dillo::Dict{Int, Dict{Int,Int}}, dilco::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}, dilko::Dict{Int, Dict{Int,Int}}, diklo::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}}}}, dikco::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}}}}, dikko::Dict{Int, Dict{Int,Int}}, mat::Array{Int,2}, dimp::Dict{Tuple{Int,Int}, Set{Int}}, dicorézlig::Dict{Int, Set{Int}}, dicorézcol::Dict{Int, Set{Int}}, dicorézcar::Dict{Int, Set{Tuple{Int,Int}}}, lesZérosàSuppr::Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}, çaNavancePas::Bool) #… voir si un chiffre est seul (ou uniquement sur une même ligne, col…). Car par exemple, s'il apparaît une seule fois sur la ligne : c'est qu'il ne peut qu'être là ^^
	# Autres exemple, si dans une ligne, il n'y a d'occurence que dans un des 3 carré, il ne pourra pas être ailleurs dans le carré.
	 for (j,dc) in dicco # pour les colonnes
		for (n,v) in dc
			if v == 1
				i = diclo[j][n][1]
				if n ∉ chiffrePossible(mat,i,j,get!(dimp,(i,j),Set{Int}() ))
					return false # pas 3a bol ^^
				end ## ou plutôt ## n ∉ simplechiffrePossible(mat,i,j) 
				mat[i,j] = n
				push!(lesZérosàSuppr, (i, j, dicko[j][n], diclo[j][n][2], diclo[j][n][3]))
				delete!(dicorézlig[i], j)
				delete!(dicorézcol[j], i)
				delete!(dicorézcar[dicko[j][n]], (i, j) )
				haskey(dillo, i) && delete!(dillo[i], n)
				haskey(dikko, dicko[j][n]) && delete!(dikko[dicko[j][n]], n)
				çaNavancePas = false # Car on a réussi à remplir
			else 
				for (lig, col) in setdiff(dicorézcar[dicko[j][n]], ((i, j) for i in diclo[j][n][2]))
					push!(get!(dimp,(lig,col),Set{Int}() ), n) # çaNavancePas & dimp ?
				end
			end
		end
	 end
	 for (i,dl) in dillo # pour les lignes
		for (n,v) in dl
			if v == 1
				j = dilco[i][n][1]
				if n ∉ chiffrePossible(mat,i,j,get!(dimp,(i,j),Set{Int}() ))
					return false # pas 3b bol ^^
				end 
				mat[i,j] = n
				push!(lesZérosàSuppr, (i, j, dilko[i][n], dilco[i][n][2], dilco[i][n][3]))
				delete!(dicorézlig[i], j)
				delete!(dicorézcol[j], i)
				delete!(dicorézcar[dilko[i][n]],(i, j) )
				# haskey(dicco,dico[i][n][1]) && delete!(dicco[dico[i][n][1]], n)#sio
				haskey(dikko,dilko[i][n]) && delete!(dikko[dilko[i][n]], n)
				çaNavancePas = false # Car on a réussi à remplir
			else 
				for (lig, col) in setdiff(dicorézcar[dilko[i][n]], ((i, j) for j in dilco[i][n][3]))
					push!(get!(dimp,(lig,col),Set{Int}() ), n)
				end
			end
		end
	 end
	 for (k,dk) in dikko # pour les karré
		for (n,v) in dk
			if v == 1
				i,j = diklo[k][n][1],dikco[k][n][1]
				if n ∉ chiffrePossible(mat,i,j,get!(dimp,(i,j),Set{Int}() ))
					return false # pas 3c bol ^^
				end 
				mat[i,j] = n
				push!(lesZérosàSuppr, (i,j, k, dikco[k][n][2], diklo[k][n][2]))
				delete!(dicorézlig[i], j)
				delete!(dicorézcol[j], i)
				delete!(dicorézcar[k], (i, j) )
				# haskey(dillo,dilo[k][n][1]) && delete!(dillo[dilo[k][n][1]], n)#sio
				# haskey(dicco,dico[k][n][1]) && delete!(dicco[dico[k][n][1]], n)#rde
				çaNavancePas = false # Car on a réussi à remplir
			else 
				if dikco[k][n][1] == 0 
					for col in setdiff(dicorézlig[diklo[k][n][1]], diklo[k][n][2])
						push!(get!(dimp,(diklo[k][n][1],col),Set{Int}() ), n)
					end
				else
					for lig in setdiff(dicorézcol[dikco[k][n][1]], dikco[k][n][2])
						push!(get!(dimp,(lig,dikco[k][n][1]),Set{Int}() ), n)
					end
				end
			end
		end
	 end
	 return çaNavancePas
	end
	function LUniclk!(diclo::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}, dicco::Dict{Int, Dict{Int,Int}}, dicko::Dict{Int, Dict{Int,Int}}, dillo::Dict{Int, Dict{Int,Int}}, dilco::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}, dilko::Dict{Int, Dict{Int,Int}}, diklo::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}}}}, dikco::Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}}}}, dikko::Dict{Int, Dict{Int,Int}}, dimp::Dict{Tuple{Int,Int}, Set{Int}}) # uniclk! pour htmlSudokuPropal
	 for (j,dc) in dicco # pour les colonnes
		for (n,v) in dc
			if v == 1
				# (diclo[j][n][1],j,dicko[j][n],diclo[j][n][2],diclo[j][n][3])
				i,k, ii,jj = diclo[j][n][1],dicko[j][n],diclo[j][n][2],diclo[j][n][3]
				for iii in 1:9 # …on retire sur la ligne et la colonne
					get!(dimp,(i,iii),Set{Int}() )
					get!(dimp,(iii,j),Set{Int}() )
					iii != j && push!(dimp[i,iii],n)
					iii != i && push!(dimp[iii,j],n)
				end
				for jjj in jj, iii in ii # …et sur le carré
					jjj != j && iii != i && push!(get!(dimp,(iii,jjj),Set{Int}() ),n)
				end
				haskey(dillo,diclo[j][n][1]) && delete!(dillo[diclo[j][n][1]], n)
				haskey(dikko,dicko[j][n]) && delete!(dikko[dicko[j][n]], n)
				# çaNavancePas = false # Car on a réussi à remplir
			else 
				for (lig,col) in setdiff(tuplecarré(diclo[j][n][2],diclo[j][n][3]), ((i,j) for i in diclo[j][n][2]))
					push!(get!(dimp,(lig,col),Set{Int}() ), n) # çaNavancePas dimp ?
				end
			end
		end
	 end
	 for (i,dl) in dillo # pour les lignes
		for (n,v) in dl
			if v == 1
				# (i,dilco[i][n][1],dilko[i][n],dilco[i][n][2],dilco[i][n][3])
				j, k, ii, jj = dilco[i][n][1],dilko[i][n],dilco[i][n][2],dilco[i][n][3]
				for iii in 1:9 # …on retire sur la ligne et la colonne
					get!(dimp,(i,iii),Set{Int}() )
					get!(dimp,(iii,j),Set{Int}() )
					iii != j && push!(dimp[i,iii],n)
					iii != i && push!(dimp[iii,j],n)
				end
				for jjj in jj, iii in ii # …et sur le carré
					jjj != j && iii != i && push!(get!(dimp,(iii,jjj),Set{Int}() ),n)
				end
				# haskey(dicco,dico[i][n][1]) && delete!(dicco[dico[i][n][1]], n)#sio
				haskey(dikko,dilko[i][n]) && delete!(dikko[dilko[i][n]], n)
				# çaNavancePas = false # Car on a réussi à remplir
			else 
				for (lig,col) in setdiff(tuplecarré(dilco[i][n][2],dilco[i][n][3]), ((i,j) for j in dilco[i][n][3]))
					push!(get!(dimp,(lig,col),Set{Int}() ), n)
				end
			end
		end
	 end
	 for (k,dk) in dikko # pour les karré
		for (n,v) in dk
			if v == 1
				# (diklo[k][n][1],dikco[k][n][1],k,dikco[k][n][2],diklo[k][n][2])
				i, j, ii, jj = diklo[k][n][1],dikco[k][n][1],dikco[k][n][2],diklo[k][n][2]
				for iii in 1:9 # …on retire sur la ligne et la colonne
					get!(dimp,(i,iii),Set{Int}() )
					get!(dimp,(iii,j),Set{Int}() )
					iii != j && push!(dimp[i,iii],n)
					iii != i && push!(dimp[iii,j],n)
				end
				for jjj in jj, iii in ii # …et sur le carré
					jjj != j && iii != i && push!(get!(dimp,(iii,jjj),Set{Int}() ),n)
				end
				# haskey(dillo,dilo[k][n][1]) && delete!(dillo[dilo[k][n][1]], n)#sio
				# haskey(dicco,dico[k][n][1]) && delete!(dicco[dico[k][n][1]], n)#rde
				# çaNavancePas = false # Car on a réussi à remplir
			else 
				if dikco[k][n][1] == 0 
					for col in setdiff(set19, diklo[k][n][2])
						push!(get!(dimp,(diklo[k][n][1],col),Set{Int}() ), n)
					end
				else
					for lig in setdiff(set19, dikco[k][n][2])
						push!(get!(dimp,(lig,dikco[k][n][1]),Set{Int}() ), n)
					end
				end
			end
		end
	 end # return çaNavancePas
	 return nothing
	end
	function pasAssezDePropal!(i::Int,j::Int, listepossibles::Set{Int},dictCheckLi::Dict{Set{Int}, Set{Int}},dictCheckCj::Dict{Set{Int}, Set{Int}},dictCheckCarré::Dict{Set{Int}, Set{Tuple{Int,Int}}},Nimp::Dict{Tuple{Int,Int}, Set{Int}}) #, setlig::Set{Int}=set19, setcol::Set{Int}=set19) ##, ii::UnitRange{Int}=carr(i), jj::UnitRange{Int}=carr(j), setcar::Set{Tuple{Int,Int}}=Set(tuplecarré(ii,jj)) ) 
	# Ici l'idée est de voir s'il y a plus chiffres à mettre que de cases : en regardant tout ! entre deux cases, trois cases… sur la ligne, colonne, carré ^^
	# Bref, s'il n'y a pas assez de propositions pour les chiffres à caser : c'est vrai
	# C'est pas faux : donc ça va. 
	# De plus, si un (ensemble de) chiffre est possible que sur certaines cellules, cela le retire du reste (en gardant via la matrice Nimp). Par exemple, sur une ligne, on a 1 à 8, la dernière cellule ne peut que être 9 -> grâce à Nimp, on retire le 9 des possibilités de toutes les cellules de la colonne, du carré (et de la ligne…) sauf pour cette dernière cellule justement ^^
	# Cela permet de limiter les possibilités pour éviter au mieux les culs de sac!
	# Etant quand-même un peu trop lourd, il faut l'utiliser que si besoin
		for (k,v) in copy(dictCheckCj) # dico # Pour les colonnes
			kk = union(k,listepossibles)
			if length(kk) > length(v)
				vv = union(v, Set(i), get(dictCheckCj, kk, Set{Int}() )) 
				if length(kk) == length(vv)
					# Les chiffres kk sont à retirer de toute la colonne sauf aux kk
					for limp in setdiff(set19, vv)
						union!(get!(Nimp,(limp,j),Set{Int}() ), kk)
					end
				end
				dictCheckCj[kk] = vv
			else 
				return true
			end
		end	
		for (k,v) in copy(dictCheckLi) # dili # Pour les lignes
			kk = union(k,listepossibles)
			if length(kk) > length(v)
				vv = union(v, Set(j), get(dictCheckLi, kk, Set{Int}() ) ) 
				if length(kk) == length(vv)
					# Les chiffres kk sont à retirer de toute la ligne sauf aux kk 
					for limp in setdiff(set19, vv)
						union!(get!(Nimp,(i,limp),Set{Int}() ), kk)
					end
				end
				dictCheckLi[kk] = vv
			else 
				return true
			end
		end
		for (k,v) in copy(dictCheckCarré) # dica # Pour les carrés
			kk = union(k,listepossibles)
			if length(kk) > length(v)
				vv = union(v, Set([(i,j)]), get(dictCheckCarré, kk, Set{Tuple{Int,Int}}() ) ) 
				if length(kk) == length(vv)
					for (limp,ljmp) in setdiff(Set(tuplecarré(carr(i),carr(j))), vv) #setcar,vv
						union!(get!(Nimp,(limp,ljmp),Set{Int}() ), kk)
					end
				end
				dictCheckCarré[kk] = vv
			else 
				return true
			end
		end	
		get!(dictCheckLi,listepossibles, Set( j ) )
		get!(dictCheckCj,listepossibles, Set( i ) )
		get!(dictCheckCarré,listepossibles, Set( [(i,j)] ) )
		return false
	end
	function puces(liste, valdéfaut=nothing ; idPuces="p"*string(rand(Int)), classe="") # Permet de faire des puces en HTML pour faire un choix unique
	# Si "🤫 Cachée" cochée, cela floute les puces du dessous (PossiblesEtSolution)
		début = "<span id='$idPuces' " *(classe=="" ? ">" : "class='$classe'>")
		fin = "</span><script>const form = document.getElementById('$idPuces')
	form.oninput = (e) => { form.value = e.target.value; " *
		(idPuces=="CacherRésultat" ? raw"if (e.target.value=='🤫 Cachée') {
		document.getElementById('PossiblesEtSolution').classList.add('pasla');
		document.getElementById('divers').classList.add('pasla');
		} else if (e.target.value=='Pour toutes les cases, voir les chiffres…') {
		document.getElementById('pucaroligne').classList.add('maistesou');
		document.getElementById('PossiblesEtSolution').classList.remove('pasla');
		document.getElementById('divers').classList.remove('pasla');
		} else {
		document.getElementById('PossiblesEtSolution').classList.remove('pasla');
		document.getElementById('divers').classList.remove('pasla');
		document.getElementById('pucaroligne').classList.remove('maistesou');
		};" : "") *
		(idPuces=="PossiblesEtSolution" ? raw"if (e.target.value=='…par total (minimum = ✔)') {
		document.getElementById('puchoixàmettreenhaut').classList.add('maistesou');
		} else {
		document.getElementById('puchoixàmettreenhaut').classList.remove('maistesou');
		};" : "") * "}</script>"
		inputs = ""
		for item in liste
			inputs *= """<span style='display:inline-block;'><input type='radio' id='$idPuces$item' name='$idPuces' value='$item' style='margin: O 4px 0 4px;' $(item == valdéfaut ? "checked" : "")><label style='margin: 0 18px 0 2px; user-select: none;' for='$idPuces$item'>$item</label></span>"""
		end
		# for (item,valeur) in liste ### si liste::Array{Pair{String,String},1}
		# 	inputs *= """<input type="radio" id="$idPuces$item" name="$idPuces" value="$item" style="margin: 0 4px 0 20px;" $(item == valdéfaut ? "checked" : "")><label for="$idPuces$item">$valeur</label>"""
		# end
		return Docs.HTML(début * inputs * fin)
	end
	vaetvient = Docs.HTML(raw"<script> var vieillecopie = false;

	function déjàvu() { 
		var père = document.getElementById('sudokincipit').parentElement;
		var fils = document.getElementById('copiefinie');
		var ancien = document.getElementById('sudokufini');
		if (vieillecopie.isEqualNode(ancien)) {
			ancien.innerHTML = fils.innerHTML;
			ancien.removeChild(ancien.querySelector('tfoot'));
			msga(ancien);
		}
		document.getElementById('sudokincipit').hidden = false;
		père.removeChild(fils);
		document.getElementById('va_et_vient').innerHTML = `Sudoku initial ⤴ (modifiable) et sa solution : `
	};

	function làhaut() { 
		var père = document.getElementById('sudokincipit').parentElement;
		var fils = document.getElementById('copiefinie');
		var copie = document.getElementById('sudokufini');
		fils ? père.removeChild( fils ) : true;
		document.getElementById('sudokincipit').hidden = true;
		var tabl = document.createElement('table');
		vieillecopie = (copie ? copie.cloneNode(true) : tabl);
		tabl.id = 'copiefinie';
		tabl.classList.add('sudokool');
		tabl.innerHTML = (copie ? copie.innerHTML : `<thead id='taide'><tr><td style='text-align: center;width: 340px;padding: 26px 0;border: 0;'>Rien à montrer, c'est coché  <code>🤫 Cachée</code></td></tr></thead>`) + `<tfoot id='tesfoot'><tr id='lignenonvisible'><th colspan='9'>↪ Cliquer ici pour revenir au sudoku modifiable</th></tr></tfoot>`;
		père.appendChild(tabl);
		document.getElementById('taide')?.addEventListener('click', déjàvu);
		document.getElementById('tesfoot').addEventListener('click', déjàvu);
		copie ? msga(document.getElementById('copiefinie')) : true;
		document.getElementById('va_et_vient').innerHTML = `Solution ↑ (au lieu du sudoku modifiable initial)`
	};
	document.getElementById('va_et_vient').addEventListener('click', làhaut);

	</script><span id='va_et_vient'>") # Pour le texte entre les deux sudoku (initaux et solution). Cela permet de remonter la solution en cliquant dessus
	# interval(mini,maxi,val) = Docs.HTML("<input type='range' min='$(mini)' max='$(maxi)' value='$(val)' oninput='this.nextElementSibling.value=this.value'><output> $(val)</output>") # slider
	interval(mini=1,maxi=1,val=maxi,id=string(rand(Int))) = Docs.HTML("<input type='range' min='$(mini)' max='$(maxi)' value='$(val)' id='i$(id)' oninput='this.nextElementSibling.value=this.value;'/><input type='number' min='$(mini)' max='$(maxi)' value='$(val)' id='o$(id)' oninput='this.previousElementSibling.value=this.value;'/>") # slider
	
	Sudini(mémo, choix) = Docs.HTML("<script> // stylélàbasavecbonus!
	const premier = JSON.stringify( $(mémo[1]) );
	const deuxième = JSON.stringify( $(mémo[2]) );
	const defaultFixedValues = $(mémo[choix])" * raw"""
				
	// const defaultFixedValues = [[0,0,0,7,0,0,0,0,0],[1,0,0,0,0,0,0,0,0],[0,0,0,4,3,0,2,0,0],[0,0,0,0,0,0,0,0,6],[0,0,0,5,0,9,0,0,0],[0,0,0,0,0,0,4,1,8],[0,0,0,0,8,1,0,0,0],[0,0,2,0,0,0,0,5,0],[0,4,0,0,0,0,3,0,0]];
			
	window.createSudokuHtml = (values) => {
	  const data = [];
	  const htmlData = [];
	  for(let i=0; i<9;i++){
	    let htmlRow = [];
	    data.push([]);
	    for(let j=0; j<9;j++){
	      const valuesLine = values[i];
	      const value = valuesLine?valuesLine[j]:0;
	      const htmlInput = html`<input type='text' 
	        data-row='${i}'
	        data-col='${j}'
	        maxlength='1' 
	        value='${(value||'')}'
	      >`;
		  const isMedium = (j%3 === 0);
		  const block = [Math.floor(i/3), Math.floor(j/3)]; // fond en damier
		  const classoupas = ((block[0]+block[1])%2 !== 0)?(isMedium?'class="damier troisd"':'class="damier"'):(isMedium?'class="troisd"':'');
	      const htmlCell = html`<td ${classoupas}>${htmlInput}</td>`
	      data[i][j] = value||0;
	      htmlRow.push(htmlCell);
	    }
		
	    const isMediumBis = (i%3 === 0);
	    htmlData.push(html`<tr ${isMediumBis?'class="troisr"':""}>${htmlRow}</tr>`);
	  }
	  const _sudoku = html`<table id="sudokincipit" sudata=${JSON.stringify(data)} class='sudokool'>
	      <tbody>${htmlData}</tbody>
	    </table>`  
	  return {_sudoku,data};
	  // // return _sudoku ;
	  
	}
	
	window.sudokuViewReactiveValue = ({_sudoku:html, data}) => {
	  html.addEventListener('input', (e)=>{
	    e.stopPropagation(); e.preventDefault(); 
	    html.value = data;
	    return false;
	  }); 
	  
	  let inputs = html.querySelectorAll('input');
	  inputs.forEach(input => {
		
		const daligne = (e) => e.target.getAttribute('data-row');
		const dacol = (e) => e.target.getAttribute('data-col');
		const etp2 = (e) => e.target.parentElement.parentElement;
		const etp3 = (e) => e.target.parentElement.parentElement.parentElement;
	
		const moveDown = (e) => { 
			if (etp2(e).nextElementSibling == null) { 
			etp3(e).childNodes[0].childNodes[dacol(e)].childNodes[0].focus();
			} else { 
			etp2(e).nextElementSibling.childNodes[dacol(e)].childNodes[0].focus();
			} 
		}
		const moveUp = (e) => {
			if (etp2(e).previousElementSibling == null) { 
			etp3(e).lastChild.childNodes[dacol(e)].childNodes[0].focus();
			} else { 
			etp2(e).previousElementSibling.childNodes[dacol(e)].childNodes[0].focus();
			} 
		}
		const moveLeft = (e) => {
			if (e.target.parentElement.previousElementSibling == null) {
				if (etp2(e).previousElementSibling == null) {
					etp3(e).lastChild.lastChild.childNodes[0].focus();
				} else {
				etp2(e).previousElementSibling.lastChild.childNodes[0].focus();
			} } else {
			e.target.parentElement.previousElementSibling.childNodes[0].focus();
			} 
		}
		const moveRight = (e) => { 
			if (e.target.parentElement.nextElementSibling == null) {
				if (etp2(e).nextElementSibling == null) {
					etp3(e).childNodes[0].childNodes[0].childNodes[0].focus();
				} else {
				etp2(e).nextElementSibling.childNodes[0].childNodes[0].focus();
			} } else { 
			e.target.parentElement.nextElementSibling.childNodes[0].focus();
			} 
		}
			
		input.addEventListener('keydown',(e) => {
		  // e.target.focus();
		  e.target.select();
			
		  switch (e.key) {
			case "ArrowDown":
				moveDown(e); break; 
			case "ArrowUp":
				moveUp(e); break; 
			case "ArrowLeft":
				moveLeft(e); break; 
			case "ArrowRight":
				moveRight(e); break; 
			case "Shift":
			case "CapsLock":
			case "NumLock":
				break; // https://www.w3.org/TR/uievents-key/#keys-modifier
			case "Backspace":
			case "Delete":
				if (data[daligne(e)][dacol(e)] !== 0) {
					data[daligne(e)][dacol(e)] = 0;
					e.target.value = "";
					// Efface les puces car cela a été touché
					var ele = document.getElementsByName("ModifierInit");
					for(var ni=0;ni<ele.length;ni++)
						ele[ni].checked = false;
					const jdata = JSON.stringify(data);
					if (jdata == premier) {
						ele[0].checked = true;
					} else if (jdata == deuxième) {
						ele[1].checked = true;
					}
					html.setAttribute('sudata', jdata);
					html.dispatchEvent(new Event('input'));
				}
				(e.key==="Delete")?moveRight(e):moveLeft(e);
				var da = document.activeElement;
				(e.key==="Delete")?(da.selectionStart = da.selectionEnd = da.value.length):(da.selectionStart = da.selectionEnd = 0); //select KO :(
				break;
			default:
				return;
			} }) 
			
	    input.addEventListener('input',(e) => {
		  const i = e.target.getAttribute('data-row'); // daligne(e)
		  const j = e.target.getAttribute('data-col'); // dacol(e)
		  const val = e.target.value //parseInt(e.target.value);
		  const oldata = data[i][j];
	
		  const bidouilliste = {a:1,z:2,e:3,r:4,t:5,y:6,u:7,i:8,o:9,
			A:1,Z:2,E:3,R:4,T:5,Y:6,U:7,I:8,O:9,
			'\&':1,é:2,'\"':3,"\'":4,'\(':5,'\-':6,è:7,_:8,ç:9,
			'§':6,'!':8,    q:1,Q:1, w:2,W:2};
	
		  const androidChromeEstChiant = {'b':moveDown,'B':moveDown,
			'h':moveUp,'H':moveUp,        'j':moveRight,'J':moveRight,
			'g':moveLeft,'G':moveLeft,'v':moveLeft,'V':moveLeft,
			'd':moveRight,'D':moveRight,'n':moveRight,'N':moveRight};
	
		  if (val in bidouilliste) {
			e.target.value = data[i][j] = bidouilliste[val];
		  } else if (val <= 9 && val >=1) {
			data[i][j] = parseInt(val);
		  } else if ((val == 0)||(val == 'à')||(val == 'p')||(val == 'P')) {
			data[i][j] = 0;
			e.target.value = '';
		  } else { 
			e.target.value = data[i][j] === 0 ? '' : data[i][j];
		  }
	
			if (oldata === data[i][j]) {
				e.stopPropagation(); e.preventDefault(); 
			} else {
				// Efface les puces car cela a été touché
				var ele = document.getElementsByName("ModifierInit");
				for(var ni=0;ni<ele.length;ni++)
					ele[ni].checked = false;
				const jdata = JSON.stringify(data);
				if (jdata == premier) {
					ele[0].checked = true;
				} else if (jdata == deuxième) {
					ele[1].checked = true;
				}
				html.setAttribute('sudata', jdata);
				html.dispatchEvent(new Event('input'));
			}
	
			if (val in androidChromeEstChiant) {
				androidChromeEstChiant[val](e);
			} else {
				moveRight(e);
			}
			document.activeElement.select();
	    })
			
	    input.addEventListener('ctop',(e) => { // mis à jour par chiffre sélectionné
		  const i = e.target.getAttribute('data-row'); // daligne(e)
		  const j = e.target.getAttribute('data-col'); // dacol(e)
		  const val = e.target.value //parseInt(e.target.value);
		  const oldata = data[i][j];
	
		  if (val <= 9 && val >=1) {
			data[i][j] = parseInt(val);
		  } else if (val == 0) {
			data[i][j] = 0;
			e.target.value = '';
		  } else { 
			e.target.value = data[i][j] === 0 ? '' : data[i][j];
		  }
			
			if (oldata === data[i][j]) {
				e.stopPropagation(); e.preventDefault(); 
			} else {
				// Efface les puces car cela a été touché
				var ele = document.getElementsByName("ModifierInit");
				for(var ni=0;ni<ele.length;ni++)
					ele[ni].checked = false;
				const jdata = JSON.stringify(data);
				if (jdata == premier) {
					ele[0].checked = true;
				} else if (jdata == deuxième) {
					ele[1].checked = true;
				}
				html.setAttribute('sudata', jdata);
				html.dispatchEvent(new Event('input'));
			}
	    })
			
	  }) 
	  var ele = document.getElementsByName("ModifierInit");
	  const jdata = JSON.stringify(data);
	  if (jdata == premier) {
		ele[0].checked = true;
	  } else if (jdata == deuxième) {
		ele[1].checked = true; // …].click(); // était KO…
	  }
	  html.setAttribute('sudata', jdata);
	  html.dispatchEvent(new Event('input'));
	  return html;
	
	};
	
	return sudokuViewReactiveValue(createSudokuHtml(defaultFixedValues));
	</script>""")
	function htmlSudoku(JSudokuFini::Union{String, Vector{Vector{Int}}}=jsvd(),JSudokuini::Union{String, Vector{Vector{Int}}}=jsvd(); toutVoir::Bool=true)
	# Pour sortir de la matrice (conversion en tableau en HTML) du sudoku
	# Le JSudokuini permet de mettre les chiffres en bleu (savoir d'où l'on vient)
	# Enfin, on peut choisir de voir petit à petit en cliquant ou toutVoir d'un coup
	### if isa(JSudokuFini, String)… avait un bug d'affichage pour le reste du code…
		isa(JSudokuFini, String) ? (return Docs.HTML("<h5 style='text-align: center;margin-bottom: 6px;user-select: none;' onclick='$footix'> ⚡ Attention, sudoku initial à revoir ! </h5><table id='sudokufini' class='sudokool' style='user-select: none;' <tbody><tr><td style='text-align: center;width: 340px;' onclick='$footix'>$JSudokuFini</td></tr></tbody></table>")) : (return Docs.HTML(raw"""<script id="scriptfini">
		// stylélàbasavecbonus!
				
		const createSudokuHtml = (values, values_ini) => {	
		  const data = [];
		  const htmlData = [];
		  for(let i=0; i<9;i++){
			let htmlRow = [];
			data.push([]);
			for(let j=0; j<9;j++){
			  const valuesLine = values[i];
			  const value = valuesLine?valuesLine[j]:0;
			  const isInitial = values_ini[i][j]>0;
			  const isMedium = (j%3 === 0);
			  const htmlCell = html`<td class='"""*(toutVoir ? raw"""${isInitial?"ini":"vide"}""" : raw"""${isInitial?"ini":"vide cachée"}""")*raw"""${isMedium?' troisd':''}' data-row='${i}' data-col='${j}'>${(value||' ')}</td>`;
			  data[i][j] = value||0;
			  htmlRow.push(htmlCell);
			}
			const isMediumBis = (i%3 === 0);
    		htmlData.push(html`<tr ${isMediumBis?'class="troisr"':""}>${htmlRow}</tr>`);
		  }
		  const _sudoku = html`<table id="sudokufini" """*(toutVoir ? "" : raw"""style="user-select: none;" """)*raw""" class='sudokool'>
			  <tbody>${htmlData}</tbody>
			</table>`  
		  // return {_sudoku,data};
		const jdataini = JSON.stringify(values_ini);
		const jdataFini = JSON.stringify(values);
  		_sudoku.setAttribute('sudataini', jdataini);
  		_sudoku.setAttribute('sudatafini', jdataFini);
		var sudokuiniàvérif = document.getElementById("sudokincipit");
		if (sudokuiniàvérif && sudokuiniàvérif.getAttribute('sudata') != jdataini) {
			return html`<h5 style='text-align: center;user-select: none;'>🚀 Recalcul rapide ;)</h5>`;
		}; // v0.19 semble de nouveau Ok -> https://mybinder.org/v2/gh/fonsp/pluto-on-binder/v0.14.7?urlpath=pluto
		return _sudoku;
				};
		window.msga = (_sudoku) => {
				"""*(toutVoir ? raw""" 
		let tds = _sudoku.querySelectorAll('td.vide');
  		tds.forEach(td => {
				
			td.addEventListener('click', (e) => {
				if (document.getElementById("choixàmettreenhaut")) {
					if (document.getElementById("choixàmettreenhaut").checked) {
						const lign = parseInt(e.target.getAttribute("data-row")) + 1;
						const colo = parseInt(e.target.getAttribute("data-col")) + 1;
						const vale = e.target.innerHTML;
						var cible = document.querySelector("#sudokincipit > tbody > tr:nth-child("+ lign +") > td:nth-child("+ colo +") > input[type=text]");
						if (!(isNaN(vale))) {
							cible.value = cible.value == vale ? 0 : vale ; 
							// e.target.classList.remove("vide");
							e.target.classList.remove("cachée");
							e.target.classList.toggle("ini"); // ini bleu ou cachée
							e.target.classList.add("gris"); 
							/* cible.value = vale; 
							e.target.classList.remove("vide");
							e.target.classList.add("ini"); */
							// document.getElementById("tesfoot")?.dispatchEvent(new Event("click"));
							cible.dispatchEvent(new Event('ctop')); 
						};
				}}; 
				
			});
		});""" : raw"""
		let tdbleus = _sudoku.querySelectorAll('td.ini');
  		tdbleus.forEach(tdbleu => {
			tdbleu.addEventListener('click', (e) => {
				var grantb = e.target.parentElement.parentElement;
				for(let grani=0; grani<9;grani++){ 
				for(let granj=0; granj<9;granj++){ 
				 if ( !(grantb.childNodes[grani].childNodes[granj].classList.contains("ini")) ) {
				grantb.childNodes[grani].childNodes[granj].classList.add("cachée");
				grantb.childNodes[grani].childNodes[granj].classList.remove("gris");
				
				} }};
			});
		});
		
		let tds = _sudoku.querySelectorAll('td.vide');
  		tds.forEach(td => {
				
			td.addEventListener('click', (e) => {
				if (document.getElementById("caroligne")?.checked) {	
					const ilig = e.target.getAttribute('data-row');
					const jcol = e.target.getAttribute('data-col'); 
					const orNicar = (lign, colo) => Math.floor(ilig/3)==Math.floor(lign/3) && Math.floor(jcol/3)==Math.floor(colo/3) ;
					var grantb = e.target.parentElement.parentElement;
					for(let grani=0; grani<9;grani++){ 
					for(let granj=0; granj<9;granj++){ 
					 var tdf = grantb.childNodes[grani].childNodes[granj];
					 if (tdf.getAttribute('data-row') == ilig || tdf.getAttribute('data-col') == jcol || orNicar(tdf.getAttribute('data-row'),tdf.getAttribute('data-col')) ) {
					  tdf.classList.remove("cachée"); // ciel gris
					} }};
				} else {
				e.target.classList.toggle("cachée");
				if(document.getElementById("choixàmettreenhaut")?.checked==false && !(e.target.classList.contains("ini")) ){e.target.classList.remove("gris")}; };
				// e.target.classList.toggle("cachée");
				
				if (document.getElementById("choixàmettreenhaut")?.checked) {
					const lign = parseInt(e.target.getAttribute("data-row")) + 1;
					const colo = parseInt(e.target.getAttribute("data-col")) + 1;
					const vale = e.target.innerHTML;
					var cible = document.querySelector("#sudokincipit > tbody > tr:nth-child("+ lign +") > td:nth-child("+ colo +") > input[type=text]");
					if (!(isNaN(vale))) {
						cible.value = cible.value == vale ? 0 : vale ; 
						// e.target.classList.remove("vide");
						e.target.classList.remove("cachée");
						e.target.classList.toggle("ini"); // ini bleu ou cachée
						e.target.classList.add("gris"); 
						/* cible.value = vale; 
						e.target.classList.remove("vide");
						e.target.classList.add("ini"); */
						// document.getElementById("tesfoot")?.dispatchEvent(new Event("click"));
						cible.dispatchEvent(new Event('ctop')); 
					};
				}; 
				
			});
		});	""")*raw"""
		  return _sudoku;

		};
		
		// sinon : return createSudokuHtml(…)._sudoku;
		return msga(createSudokuHtml(""" *"$JSudokuFini"*", "*"$JSudokuini"*""") );
		</script>""")
		)### end ### if isa(JSudokuFini, String)… suite et fin du bug d'affichage
	end
	htmls = htmlSudoku ## mini version (ou alias plus court si besoin)
	htmat = htmlSudoku ∘ matriceàlisteJS ## mini version 

	const pt1 = "·" # "." ## Caractères de remplissage pour mieux voir le nbPropal
	const pt2 = "◌" # "○" # "◘" # "-" # ":"
	const pt3 = "●" # "■" # "▬" # "—" # "⁖" # "⫶"
	function chiffrePropal(mat::Array{Int,2},limp::Set{Int},i::Int,j::Int,vide::Bool) # Remplit une case avec tous ses chiffres possibles, en mettant le 1 en haut à gauche et le 9 en bas à droite (le 5 est donc au centre). S'il n'y a aucune possibilité, on remplit tout avec des caractères bizarres ‽
	# Pour mise en forme en HTML mat3 : 3x3 (une matrice de 3 lignes et 3 colonnes)
		cp = chiffrePossible(mat,i,j,limp)
		if isempty(cp)
			return [["◜","‽","◝"],["¡","/","!"],["◟","_","◞"]]
			# return [["⨯","⨯","⨯"],["⨯","⨯","⨯"],["⨯","⨯","⨯"]]
		end
		# lcp = length(cp)
		# vi = (vide ? " " : (lcp<4 ? pt1 : (lcp<7 ? pt2 : pt3)))
		vi = (vide ? " " : "·") #"◦") # "⨯") # pt1) ## retour à pt1 ^^
		return matriceàlisteJS(reshape([((x in cp) ? string(x) : vi) for x in 1:9], (3,3)),3)
	end
	function nbPropal(mat::Array{Int,2},limp::Set{Int},i::Int,j::Int) # Assez proche de chiffrePropal ci-dessus, mais ne montre pas les chiffres possibles. Cela montre le nombres de chiffres possibles, en remplissant petit à petit avec pt1 à pt3 suivant.
	# Pour mise en forme en HTML mat3 : 3x3
		lcp = length(chiffrePossible(mat,i,j,limp))
		if lcp == 0
			return [["↘","↓","↙"],["→","0","←"],["↗","↑","↖"]], 0
		else
			return matriceàlisteJS(reshape([(x == lcp ? string(x) : (x<lcp ? (lcp<4 ? pt1 : (lcp<7 ? pt2 : pt3)) : " ")) for x in 1:9], (3,3)),3), lcp
		end
	end
	function htmlSudokuPropal(JSudokuini::Union{String, Vector{Vector{Int}}}=jsvd(),JSudokuFini::Union{String, Vector{Vector{Int}}}=jsvd() ; toutVoir::Bool=true, parCase::Bool=true, somme::Bool=true)
	# Assez proche de htmlSudoku, mais n'a pas besoin d'avoir un sudoku résolu en entrée. En effet, il ne montre que les chiffres (ou leur nombre = somme) possibles pour le moment.
	# Il y a plusieurs cas : (cela est peutêtre à changer)
		# toutVoir ou non : découvre tous les cellules si toutVoir (sinon à cliquer)
		# parCase : découvre une celle cellule (sinon plusieurs)
		# somme : voir juste le nombre de possibilité, sinon, voir les possibilités
		mS::Array{Int,2} = listeJSàmatrice(JSudokuini)
		# mImp = [ Set{Int}() for _ = 1:9, _ = 1:9 ]
		mImp = Dict{Tuple{Int,Int}, Set{Int}}()
		while true
			nAwak = deepcopy(mImp)
			vérifligne = [ Dict{Set{Int}, Set{Int}}() for _ = 1:9 ]
			vérifcol = [ Dict{Set{Int}, Set{Int}}() for _ = 1:9 ]
			vérifcarré = [ Dict{Set{Int}, Set{Tuple{Int,Int}} }() for _ = 1:9 ]
			dillo = Dict{Int, Dict{Int,Int}}() 
			dilko = Dict{Int, Dict{Int,Int}}() 
			dicco = Dict{Int, Dict{Int,Int}}() 
			dicko = Dict{Int, Dict{Int,Int}}() 
			dikko = Dict{Int, Dict{Int,Int}}() 
			dilco = Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}()
			diclo = Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}()
			dikco = Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}} }}()
			diklo = Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}} }}()
			fusibleslig = Dict{Int, Set{Int}}()
			fusiblescol = Dict{Int, Set{Int}}()
			fusiblescar = Dict{Int, Set{Int}}()
			for j in 1:9, i in 1:9
				if mS[i,j] == 0
					get!(mImp,(i,j),Set{Int}() )
					lcp = chiffrePossible(mS,i,j,mImp[i,j])
					k = kelcarré(i,j)
					ii = carr(i)
					jj = carr(j)
					sac!(j,i,k,ii,jj,lcp,fusiblescol,dicco,diclo,dicko)
					sac!(i,j,k,ii,jj,lcp,fusibleslig,dillo,dilco,dilko)
					sak!(i,j,k,ii,jj,lcp,fusiblescar,diklo,dikco,dikko)
					if length(lcp) == 1
						for iii in 1:9 # …on retire sur la ligne et la colonne
							get!(mImp,(i,iii),Set{Int}() )
							get!(mImp,(iii,j),Set{Int}() )
							iii != j && union!(mImp[i,iii],lcp)
							iii != i && union!(mImp[iii,j],lcp)
						end
						# for jj in carr(j), ii in carr(i) # …et sur le carré
						for jjj in jj, iii in ii # …et sur le carré
							# jj != j && ii != i && union!(mImp[ii,jj],Set(lcp))
							jjj != j && iii != i && union!(get!(mImp,(iii,jjj),Set{Int}() ),lcp)
						end
					else pasAssezDePropal!(i, j, lcp, vérifligne[i], vérifcol[j], vérifcarré[k], mImp ) 
					end
				end
			end
			LUniclk!(diclo,dicco,dicko,dillo,dilco,dilko,diklo,dikco,dikko,mImp)
			if mImp == nAwak
				break
			end
		end
		if somme	
			mnPropal = fill(fill( fill("0",3),3) , (9,9) )
			mine = 10
			grisemine = Tuple{Int,Int}[]
			for j in 1:9, i in 1:9
				if mS[i,j] == 0
				mnPropal[i,j], lcp = nbPropal(mS, mImp[i,j], i, j)
					if lcp < mine
						mine = lcp
						grisemine = [(i,j)]
					elseif lcp == mine
						push!(grisemine, (i,j))
					end
				end
			end
			parCase = toutVoir # bidouille à changer ?
			toutVoir = true
			if 0 < mine < 9
				for (i,j) in grisemine
					mnPropal[i,j][3][3] = "✔"
				end
			end
			JPropal = matriceàlisteJS(mnPropal)
		else
			mPropal = fill(fill( fill("0",3),3) , (9,9) )
			for j in 1:9, i in 1:9
				if mS[i,j] == 0
					mPropal[i,j] = chiffrePropal(mS, mImp[i,j], i, j, parCase)
				end
			end
			JPropal = matriceàlisteJS(mPropal)
		end
			
		return Docs.HTML(raw"""<script id="scriptfini">
		// stylélàbasavecbonus!
		
		// const kelcarJS = (lig, col) => [Math.floor(lig/3), Math.floor(col/3)];
		const MMcar = (lig, col, lign, colo) => Math.floor(lig/3)==Math.floor(lign/3) && Math.floor(col/3)==Math.floor(colo/3) ;
		
		const createSudokuHtml = (mvalues, values_ini) => {	
		  const data = [];
		  const htmlData = [];
		  for(let i=0; i<9;i++){
			let htmlRow = [];
			data.push([]);
			for(let j=0; j<9;j++){
				
			  	const htmlMiniData = [];
				const isInitial = values_ini[i][j]>0;
				var mini_sudoku = values_ini[i][j];
				if (!(isInitial)) {
				  for(let pl=0; pl<3;pl++){
					let htmlMiniRow = [];
					for(let pj=0; pj<3;pj++){
					const miniValue = mvalues[i][j][pl][pj];
					const htmlMiniCell = html`<td class="mini"""*(toutVoir && parCase ? "\"" : raw"""${isInitial?' prop':' vide cachée'}" """)*raw""" data-row="${pl}" data-col="${pj}">${(miniValue||' ')}</td>`; 
					htmlMiniRow.push(htmlMiniCell);
					}
					htmlMiniData.push(html`<tr style="border-style: none !important;">${htmlMiniRow}</tr>`);
				  }
				var mini_sudoku = html`<table class="sudokoolmini" style="user-select: none;">
			  <tbody>${htmlMiniData}</tbody>
			</table>`
				}
			  const valuee = mini_sudoku;
			  const isMedium = (j%3 === 0);
			  const htmlCell = html`<td class="${isInitial?'ini':'props'} ${isMedium?' troisd':''}" data-row="${i}" data-col="${j}">${(valuee||' ')}</td>`;
			  data[i][j] = valuee||0;
			  htmlRow.push(htmlCell);
			}
			const isMediumBis = (i%3 === 0);
    		htmlData.push(html`<tr ${isMediumBis?'class="troisr"':''}>${htmlRow}</tr>`);
		  }
		  const _sudoku = html`""" * (isa(JSudokuFini, String) ? "<h5 style='text-align: center;user-select: none;' onclick='$footix'> ⚡ Attention, sudoku initial à revoir ! </h5>" : "") * raw"""<table id="sudokufini" class="sudokool" style="user-select: none;">
			  <tbody>${htmlData}</tbody>
			</table>`  
			
		const jdataini = JSON.stringify(values_ini);
		const jdataFini = JSON.stringify(mvalues);
  		_sudoku.setAttribute('sudataini', jdataini);
  		_sudoku.setAttribute('sudatafini', jdataFini);
		var sudokuiniàvérif = document.getElementById("sudokincipit");
		if (sudokuiniàvérif && sudokuiniàvérif.getAttribute('sudata') != jdataini) {
			return html`<h5 style='text-align: center;user-select: none;'>🚀 Recalcul rapide ;)</h5>`;
		}; // entre Pluto >v0.14.7 et 0.19 cf. plus haut
		return _sudoku;
			};
			window.msga = (_sudoku) => {
				const justeremonte = (tdmini) => { // 3 et 2+3
				"""*(somme ? raw"" : raw"""
				tdmini.forEach(td => {
					td.addEventListener('click', (e) => {
						
						if (document.getElementById("choixàmettreenhaut")?.checked) {
							const lign = parseInt(e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-row')) + 1; // 3 et 2+3
							const colo = parseInt(e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-col')) + 1;
							const vale = e.target.innerHTML; // NaN → pas besoin
							var cible = document.querySelector("#sudokincipit > tbody > tr:nth-child("+ lign +") > td:nth-child("+ colo +") > input[type=text]");
							if (!(isNaN(vale))) {
								cible.value = cible.value == vale ? 0 : vale ; 
								// e.target.classList.toggle("ini"); // ini bleu
								if (e.target.classList.contains("ini")) {
									e.target.classList.remove("ini");} else {
e.target.parentElement.parentElement.childNodes.forEach(tr => {
	tr.childNodes.forEach(tdd => {
									tdd.classList.remove("ini");
									})}); e.target.classList.add("ini");};
								e.target.classList.add("gris"); 
								// document.getElementById("tesfoot")?.dispatchEvent(new Event("click"));
								cible.dispatchEvent(new Event('ctop')); 
							};
						};	
						
				})}); """)*raw"""};

				const carolign = (e) => { // 3 et 1… à la base
					const ilig = e.target.getAttribute('data-row');
					const jcol = e.target.getAttribute('data-col'); 
					const granlig = e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-row');
					const grancol = e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-col'); 
					const orNicar = (tlig,tcol) => MMcar(granlig,grancol,tlig,tcol);
					e.target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.childNodes.forEach(tr => {
						tr.childNodes.forEach(tdd => {
							if ((tdd.childNodes[0].childNodes[1]!=null) && (tdd.getAttribute('data-row') == granlig || tdd.getAttribute('data-col') == grancol || orNicar(tdd.getAttribute('data-row'),tdd.getAttribute('data-col')) )){
								tdd.childNodes[0].childNodes[1].childNodes[ilig].childNodes[jcol].classList.remove("cachée"); // ciel gris
							} });
					});
				}; 

				const casecarolign = (e) => { // 2 et 2 bonus
					const ilig = e.target.getAttribute('data-row');
					const jcol = e.target.getAttribute('data-col'); 
					const granlig = e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-row');
					const grancol = e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-col'); 
					const orNicar = (tlig,tcol) => MMcar(granlig,grancol,tlig,tcol);
					e.target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.childNodes.forEach(tr => {
						tr.childNodes.forEach(tdd => {
							if ((tdd.childNodes[0].childNodes[1]!=null) && (tdd.getAttribute('data-row') == granlig || tdd.getAttribute('data-col') == grancol || orNicar(tdd.getAttribute('data-row'),tdd.getAttribute('data-col')) )){
								tdd.childNodes[0].childNodes[1].childNodes.forEach(ligne => {
								  ligne.childNodes.forEach(colon => {
									colon.classList.remove("cachée"); // ciel gris
								  });
								}); 
							} });
					});
				}; 
				
				const tousleségalit = (e) => {
					const ilig = e.target.getAttribute('data-row');
					const jcol = e.target.getAttribute('data-col'); 	
					e.target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.childNodes.forEach(tr => {
							tr.childNodes.forEach(tdd => {
								if (tdd.childNodes[0].childNodes[1]!=null){
									tdd.childNodes[0].childNodes[1].childNodes[ilig].childNodes[jcol].classList.toggle("cachée");
									if(document.getElementById("choixàmettreenhaut")?.checked==false){tdd.childNodes[0].childNodes[1].childNodes[ilig].childNodes[jcol].classList.remove("gris")};
							}});
					});		
				};

				const justeunecase = (tdmini) => { // 2 et 2
				justeremonte(tdmini);
				tdmini.forEach(td => {
					td.addEventListener('click', (e) => {		
					if (document.getElementById("caroligne")?.checked) {	
						casecarolign(e);
					} else {
						e.target.parentElement.parentElement.childNodes.forEach(ligne => {
						  ligne.childNodes.forEach(colon => {
							colon.classList.toggle("cachée");
							if(document.getElementById("choixàmettreenhaut")?.checked==false){colon.classList.remove("gris")};
						  });
						}); 
					} });	
				}) };
				
				const tousleségalitios = (tdmini) => { // 2 et 1
				justeremonte(tdmini);
				tdmini.forEach(td => {
					td.addEventListener('click', (e) => {
						"""*(somme ? raw"""if (document.getElementById("caroligne")?.checked) {	
								carolign(e);
							} else {
								tousleségalit(e) };
						""" : raw"""tousleségalit(e); """)*raw"""
				})}) };
				
				const carolignios = (tdmini) => { // 3 et 1
				justeremonte(tdmini);
				tdmini.forEach(td => {
					td.addEventListener('click', (e) => {
					if (document.getElementById("caroligne")?.checked) {
						carolign(e);
					} else {
						e.target.classList.toggle("cachée");
						if(document.getElementById("choixàmettreenhaut")?.checked==false){e.target.classList.remove("gris")} };
				}) }) }; 
				
				const touteffacer = (tdbleus) => {
					tdbleus.forEach(tdbleu => {
						tdbleu.addEventListener('click', (e) => {
							var grantb = e.target.parentElement.parentElement;
							for(let grani=0; grani<9;grani++){ 
							for(let granj=0; granj<9;granj++){ 
							 if (grantb.childNodes[grani].childNodes[granj].childNodes[0].childNodes[1]!=null) {
							for(let minii=0; minii<3;minii++){ 
							for(let minij=0; minij<3;minij++){ 
							grantb.childNodes[grani].childNodes[granj].childNodes[0].childNodes[1].childNodes[minii].childNodes[minij].classList.add("cachée");
							grantb.childNodes[grani].childNodes[granj].childNodes[0].childNodes[1].childNodes[minii].childNodes[minij].classList.remove("gris");
							
							}} } }};
						});
					}); };
				
				
		let tdmini = _sudoku.querySelectorAll('td.mini'); 
		// /parCase = toutVoir # bidouille à changer ? /toutVoir = true /// plus haut
  		"""*(toutVoir && parCase ? raw"""justeremonte(tdmini);/* 3 et 2+3 */
			""" : raw""" let tdbleus = _sudoku.querySelectorAll('td.ini'); touteffacer(tdbleus); 
				"""*(parCase ? raw"""justeunecase(tdmini); /* 2 et 2 */ 
					""" : (toutVoir ? raw"""tousleségalitios(tdmini); /* 3 et 1 + 2 et 3 */ """ : raw"""carolignios(tdmini); /* 2 et 1 */ """)))* raw"""
		  return _sudoku;
		};
		// sinon : return createSudokuHtml(…)._sudoku;
		return msga(createSudokuHtml(""" *"$JPropal"*", "*"$JSudokuini"*"""));
		</script>""")
	end
	htmlsp = htmlSudokuPropal ## mini version
	htmatp = htmlSudokuPropal ∘ matriceàlisteJS ## mini version 
	
#####################################################################################
# Fonction pricipale qui résout n'importe quel sudoku (même faux) ###################
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #
  function résoutSudokuMax(mS::Array{Int,2}, lesZéros::Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}, dicorézlig::Dict{Int, Set{Int}}, dicorézcol::Dict{Int, Set{Int}}, dicorézcar::Dict{Int, Set{Tuple{Int,Int}}} ; tours::Int = 0) 
	nbToursTotal = tours # ce nombre reprend le passage via résoutSudoku
	# lesZéros = Set(vZéros) ## avant Set(shuffle!(vZéros)) # Set une bonne ^^
	listedechoix = Tuple{Int,Int,Int,Int,Set{Int}}[]
	listedancienneMat = Array{Int,2}[]
	listedesZéros = Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}[]
	leZéroàSuppr = (0,0,0,0:0,0:0) # Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}
	nbChoixfait = 0
	minChoixdesZéros = 10
	allerAuChoixSuivant = false
	choixPrécédent = choixAfaire = (0,0,0,0,Set{Int}()) 
	listedancienImp = Dict{Tuple{Int,Int}, Set{Int}}[] # si dicOk 
	listedicorézlig = Dict{Int, Set{Int}}[]
	listedicorézcol = Dict{Int, Set{Int}}[]
	listedicorézcar = Dict{Int, Set{Tuple{Int,Int}}}[] 
	mImp = Dict{Tuple{Int,Int}, Set{Int}}()
	çaNavancePas = true # Permet de voir si rien ne se remplit en un tour
	lesZérosàSuppr=Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}()
	while !isempty(lesZéros) # && nbToursTotal < nbToursMax
		if !allerAuChoixSuivant
			nbToursTotal += 1
			çaNavancePas = true # reset à chaque tour
			minChoixdesZéros = 10
			dillo = Dict{Int, Dict{Int,Int}}() 
			dilko = Dict{Int, Dict{Int,Int}}() 
			dicco = Dict{Int, Dict{Int,Int}}() 
			dicko = Dict{Int, Dict{Int,Int}}() 
			dikko = Dict{Int, Dict{Int,Int}}() 
			dilco = Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}()
			diclo = Dict{Int,Dict{Int,Tuple{Int,UnitRange{Int},UnitRange{Int}}}}()
			dikco = Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}} }}()
			diklo = Dict{Int, Dict{Int,Tuple{Int,UnitRange{Int}} }}()
			fusibleslig = Dict{Int, Set{Int}}()
			fusiblescol = Dict{Int, Set{Int}}()
			fusiblescar = Dict{Int, Set{Int}}()
			vérifligne = [ Dict{Set{Int}, Set{Int}}() for _ = 1:9 ]
			vérifcol = [ Dict{Set{Int}, Set{Int}}() for _ = 1:9 ]
			vérifcarré = [ Dict{Set{Int}, Set{Tuple{Int,Int}} }() for _ = 1:9 ]
			for (i,j,k,ii,jj) in lesZéros
				listechiffre = chiffrePossible(mS,i,j,get!(mImp,(i,j),Set{Int}() ),ii,jj) 
				sac!(j,i,k,ii,jj,listechiffre,fusiblescol,dicco,diclo,dicko)
				sac!(i,j,k,ii,jj,listechiffre,fusibleslig,dillo,dilco,dilko)
				sak!(i,j,k,ii,jj,listechiffre,fusiblescar,diklo,dikco,dikko)
				if isempty(listechiffre) || pasAssezDePropal!(i,j,listechiffre, vérifligne[i], vérifcol[j], vérifcarré[k],mImp)
					allerAuChoixSuivant = true # donc mauvais choix
			lesZérosàSuppr=Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}()
					break
				elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
					mS[i,j]=collect(listechiffre)[1] # le Set en liste
					# mS[i,j]=pop!(listechiffre) ## ne fonctionne pas
					push!(lesZérosàSuppr, (i,j,k,ii,jj))
					delete!(dicorézlig[i],j)
					delete!(dicorézcol[j],i)
					delete!(dicorézcar[k],(i,j) )
					haskey(dillo,i) && delete!(dillo[i], mS[i,j]) # utile et sûr
					haskey(dicco,j) && delete!(dicco[j], mS[i,j])
					haskey(dikko,k) && delete!(dikko[k], mS[i,j])
					çaNavancePas = false # Car on a réussi à remplir
				elseif çaNavancePas && length(listechiffre) < minChoixdesZéros
					minChoixdesZéros = length(listechiffre)
					choixAfaire = (i,j, 1, minChoixdesZéros, listechiffre) 
					leZéroàSuppr = (i,j,k,ii,jj) # On garde les cellules avec … 
				end # … le moins de choix à faire, si ça n'avance pas
			end
		end # if allerAuChoixSuivant || çaNavancePas && (dImp == mImp) # en mieux ^^
		if allerAuChoixSuivant || uniclk!(diclo,dicco,dicko,dillo,dilco,dilko,diklo,dikco,dikko,mS,mImp,dicorézlig,dicorézcol,dicorézcar,lesZérosàSuppr,çaNavancePas)
			if allerAuChoixSuivant # Si le choix en cours n'est pas bon
				if isempty(listedechoix) # pas de bol hein
					# @info "1mp $nbToursTotal $nbChoixfait"
					return impossible # faux car trop contraint → ex: 12345678+9 ##, (tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat) 
				elseif choixPrécédent[3] < choixPrécédent[4] # Aller au suivant
					## push!(listeHistoMat , copy(mS)) ## histoire 1 
					## push!(listeHistoChoix , choixPrécédent) ## histoire 1 
					## push!(listeHistoToursTotal , (nbTours, nbToursTotal)) ## hi1 
					## nbHistoTot += 1 ## histoire 1
					(i,j, choix, l, lc) = choixPrécédent
					choixPrécédent = (i,j, choix+1, l, lc)
					listedechoix[nbChoixfait] = choixPrécédent
					mS = copy(listedancienneMat[nbChoixfait])
					mImp = deepcopy(listedancienImp[nbChoixfait])
					allerAuChoixSuivant = false
					mS[i,j] = pop!(lc)
					lesZéros = copy(listedesZéros[nbChoixfait])
					dicorézlig = deepcopy(listedicorézlig[nbChoixfait])
					dicorézcol = deepcopy(listedicorézcol[nbChoixfait])
					dicorézcar = deepcopy(listedicorézcar[nbChoixfait])
				elseif length(listedechoix) < 2 # pas 2 bol
					# @info "2bal $nbToursTotal $nbChoixfait"
					return impossible
				else # Il faut revenir d'un cran dans la liste historique
					map(pop!,(listedechoix,listedancienneMat,listedancienImp, listedesZéros,listedicorézlig,listedicorézcol,listedicorézcar))
					nbChoixfait -= 1
					choixPrécédent = listedechoix[nbChoixfait]
				end
			else # Nouveau choix à faire et à garder en mémoire
				push!(listedechoix, choixAfaire) # ici pas besoin de copie
				push!(listedancienneMat , copy(mS)) # copie en dur
				push!(listedancienImp , deepcopy(mImp)) # copie en dur
				delete!(lesZéros, leZéroàSuppr) # On retire ceux… idem set
				push!(listedesZéros , copy(lesZéros)) # copie en dur aussi
				nbChoixfait += 1

				isuppr = leZéroàSuppr[1]
				jsuppr = leZéroàSuppr[2]
				ksuppr = leZéroàSuppr[3]
				## mS[choixAfaire[1:2]...] = pop!(choixAfaire[5])
				mS[isuppr, jsuppr] = pop!(choixAfaire[5])

				delete!(dicorézlig[isuppr],jsuppr)
				delete!(dicorézcol[jsuppr],isuppr)
				delete!(dicorézcar[ksuppr],(isuppr,jsuppr) )
				push!(listedicorézlig, deepcopy(dicorézlig))
				push!(listedicorézcol, deepcopy(dicorézcol))
				push!(listedicorézcar, deepcopy(dicorézcar))

				choixPrécédent = choixAfaire
			end 
		else # !çaNavancePas && !allerAuChoixSuivant ## Tout va bien ici
			setdiff!(lesZéros, lesZérosàSuppr) # On retire ceux remplis 
			lesZérosàSuppr=Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}()
		end	
	end
	return toutestbienquifinitbien(mS, nbChoixfait, nbToursTotal)
  end
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  function résoutSudoku(JSudoku::Vector{Vector{Int}} ; nbToursMax::Int = 81) 
	nbToursTotal::Int = 0
	mS::Array{Int,2} = listeJSàmatrice(JSudoku) # Converti en vraie matrice
	lesZéros = Set(shuffle!([(i,j) for j in 1:9, i in 1:9 if mS[i,j]==0]))
	listedechoix = Tuple{Int,Int,Int,Int,Set{Int}}[]
	listedancienneMat = Array{Int,2}[]
	listedesZéros = Set{Tuple{Int,Int}}[]
	nbChoixfait = 0
	minChoixdesZéros = 10
	allerAuChoixSuivant = false
	choixPrécédent = choixAfaire = (0,0,0,0,Set{Int}()) 
	çaNavancePas = true # Permet de voir si rien ne se remplit en un tour
	lesZérosàSuppr=Set{Tuple{Int,Int}}()
	if vérifSudokuBon(mS)
		while !isempty(lesZéros) && nbToursTotal < nbToursMax
		## for nbt in 1:nbToursMax ### mauvaise idée
			## isempty(lesZéros) && (nbToursTotal += nbt - 1; break)
			if !allerAuChoixSuivant
				nbToursTotal += 1
				çaNavancePas = true # reset à chaque tour ? idem pour le reste ?
				minChoixdesZéros = 10
				for (i,j) in lesZéros
					listechiffre = simplechiffrePossible(mS,i,j) 
					if isempty(listechiffre)
						allerAuChoixSuivant = true # donc mauvais choix
						lesZérosàSuppr=Set{Tuple{Int,Int}}()
						break
					elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
						mS[i,j]=collect(listechiffre)[1] ## avant le Set en liste
						# mS[i,j]=pop!(listechiffre) ## ne fonctionne pas
						push!(lesZérosàSuppr, (i,j))
						çaNavancePas = false # Car on a réussi à remplir
					elseif çaNavancePas && length(listechiffre) < minChoixdesZéros
						minChoixdesZéros = length(listechiffre)
						choixAfaire = (i,j, 1, minChoixdesZéros, listechiffre)  
						end # …le moins de choix à faire, si ça n'avance pas
				end
			end
			### if allerAuChoixSuivant || çaNavancePas 
			if allerAuChoixSuivant # Si le choix en cours n'est pas bon
				if isempty(listedechoix) # pas de bol hein
					return impossible
				elseif choixPrécédent[3] < choixPrécédent[4] # Aller au suivant 
					(i,j, choix, l, lc) = choixPrécédent
					choixPrécédent = (i,j, choix+1, l, lc)
					listedechoix[nbChoixfait] = choixPrécédent
					mS = copy(listedancienneMat[nbChoixfait])
					allerAuChoixSuivant = false
					mS[i,j] = pop!(lc)
					lesZéros = copy(listedesZéros[nbChoixfait])
				elseif length(listedechoix) < 2 # pas 2 bol
					return impossible
				else # Il faut revenir d'un cran dans la liste historique 
					map(pop!,(listedechoix,listedancienneMat, listedesZéros))
					nbChoixfait -= 1
					choixPrécédent = listedechoix[nbChoixfait]
				end
			elseif çaNavancePas # Nouveau choix à faire et à garder en mémoire 
				push!(listedechoix, choixAfaire) # ici pas besoin de copie
				push!(listedancienneMat , copy(mS)) # copie en dur
				delete!(lesZéros, choixAfaire[1:2]) # On retire ceux… idem set ?
				push!(listedesZéros , copy(lesZéros)) # copie en dur aussi 
				nbChoixfait += 1
				mS[choixAfaire[1:2]...] = pop!(choixAfaire[5])
				choixPrécédent = choixAfaire
				### end 
			else # !çaNavancePas && !allerAuChoixSuivant ## Tout va bien ici
				setdiff!(lesZéros, lesZérosàSuppr) # On retire ceux remplis 
				lesZérosàSuppr=Set{Tuple{Int,Int}}()
			end	
		end
	else return àcorriger
	end
	if nbToursTotal == nbToursMax || nbToursTotal > nbToursMax
		mCopie = get(listedancienneMat, 1, copy(mS))
		vZéros = Set{Tuple{Int,Int,Int,UnitRange{Int},UnitRange{Int}}}()
		dicorézlig = Dict{Int, Set{Int}}()
		dicorézcol = Dict{Int, Set{Int}}()
		dicorézcar = Dict{Int, Set{Tuple{Int,Int}}}()
		for j in 1:9, i in 1:9 
			if mCopie[i,j]==0
				k = kelcarré(i,j)
				push!(vZéros, (i,j,k,carr(i),carr(j)) )
				push!(get!(dicorézlig,i,Set{Int}() ),j)
				push!(get!(dicorézcol,j,Set{Int}() ),i)
				push!(get!(dicorézcar,k,Set{Tuple{Int,Int}}() ),(i,j) )
			end
		end 
		return résoutSudokuMax(mCopie, vZéros, dicorézlig, dicorézcol, dicorézcar; tours=nbToursTotal) 
	else return toutestbienquifinitbien(mS, nbChoixfait, nbToursTotal)
	end
  end
  rjs = résoutSudoku ## mini version   ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  rmat = résoutSudoku ∘ matriceàlisteJS ## mini version   ## ## ## ## ## ## ## ## ##
# Fin de la fonction principale : résoutSudoku  ####################################
####################################################################################
  function sudokuAléatoireFini() ## Génère un sudoku aléatoire fini (aucun vide)
	return listeJSàmatrice(résoutSudoku(jsvd())[1])
  end
  saf = maf = sudokuAléatoireFini ## mini version
  function sudokuAléatoire(x=19:62 ; fun=rand, matzéro=sudokuAléatoireFini())#rand1:81
  # Une fois le sudokuAléatoireFini, on le vide un peu d'un nombre x de cellules
	if !isa(x, Int) # Permet de choisir le nombre de zéro ou un intervale
		x=fun(x)
	end
	x = (0 <= x < 82) ? x : 81 # Pour ceux aux gros doigts, ou qui voit trop grand
	liste = shuffle!([(i,j) for i in 1:9 for j in 1:9])
	for (i,j) in liste[1:x] # nbApproxDeZéros
		matzéro[i,j] = 0
	end
	return matriceàlisteJS(matzéro)
  end

  function vieuxSudoku!(nouveau=sudokuAléatoire() ; défaut=false, mémoire=SudokuMémo, matzéro=sudokuAléatoireFini(), idLien="lien"*string(rand(Int)))
  # On peut retrouver un vieuxSudoku! pour le mettre au lieu du sudoku initial
  ## Exemple de sudoku :
  # vieuxSudoku!([[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,3,0,8,5],[0,0,1,0,2,0,0,0,0],[0,0,0,5,0,7,0,0,0],[0,0,4,0,0,0,1,0,0],[0,9,0,0,0,0,0,0,0],[5,0,0,0,0,0,0,7,3],[0,0,2,0,1,0,0,0,0],[0,0,0,0,4,0,0,0,9]])
	if défaut==true # Mégalomanie ## On revient à mon défaut ^^
		mémoire[2] = copy(mémoire[4])
	elseif isa(nouveau, Int) || isa(nouveau, UnitRange{Int})
		mémoire[2] = sudokuAléatoire(nouveau ; matzéro=matzéro)
	elseif nouveau==mémoire[1] 
		mémoire[2] = sudokuAléatoire()
	else mémoire[2] = copy(nouveau) # Astuce pour sauver le sudoku en cours
	end
	return Docs.HTML("""<script>
	var ele = document.getElementsByName("ModifierInit");
	for(var ni=0;ni<ele.length;ni++)
		ele[ni].checked = false;

	function goSudokuIni() {
		document.getElementsByName("ModifierInit")[1].click();
	}
	document.getElementById("$idLien").addEventListener("click", goSudokuIni);
	goSudokuIni();
	window.location.href = "#ModifierInit";
	</script><h6 style="margin-top: 0;"> Ci-dessous, le bouton ▶ restore le vieux sudoku en sudoku initial ! 🥳 <a id="$idLien" href='#ModifierInit'> retour en haut ↑ </a> </h6>""")
  end
  vieux = vieux! = vs = vs! = vS! = vieuxSudoku! ## mini version
  vsd() = vieuxSudoku!(défaut=true) ## Pour revenir à l'original
  ini = défaut = defaut = vsd ## mini version
  vsr() = vieuxSudoku!(0) ## Pour partir d'un sudoku rempli ou fini ^^
  vsf = vsr ## mini version
  sudokuinitial!() = vieuxSudoku!(SudokuMémo[3])
  vieuxSudoku!(nouveau::Array{Int,2} ; défaut=false, mémoire=SudokuMémo, matzéro=sudokuAléatoireFini(), idLien="lien"*string(rand(Int))) = vieuxSudoku!(matriceàlisteJS(nouveau'); défaut=défaut, mémoire=mémoire, matzéro=matzéro, idLien=idLien)
  
  #= D'autres fonctions si besoin pour tester et repérer des erreurs :
  function sudokuAlt(nbChiffresMax=rand(26:81), moinsOK=true, nbessai=1) 
  # Sorte de sudokuAléatoire mais un peu plus foireux, en effet, il n'est pas forcément réalisable. C'était surtout pour faire des tests.
	nbChiffres = 1
	
	mS::Array{Int,2} = zeros(Int, 9,9) # Matrice de zéro
	lesZéros = shuffle!([(i,j) for j in 1:9, i in 1:9])# Fast & Furious
	
	for (i,j) in lesZéros
		if nbChiffres > nbChiffresMax
			return mS
		else 
		listechiffre = simplechiffrePossible(mS,i,j)
			if isempty(listechiffre) ### Pas bon signe ^^
				if moinsOK || nbessai > 26
					return mS
				else 
					return sudokuAlt(nbChiffresMax, false, nbessai+1)
				end
			else # length(listechiffre) == 1 # L'idéal, une seule possibilité
				# mS[i,j]=collect(listechiffre)[1]
				mS[i,j]=pop!(listechiffre)
				nbChiffres += 1
			end
		end
	end
  end
  salt = sudokuAlt ## mini version
  function blindtest(nbtest=100 ; tmax=81, nbzéro = (rand, 7:77), sudf=sudokuAléatoireFini)
  # Permet de tester la rapidité et certains bugs de ma fonction principale résoutSudoku. C'est donc une fonction qui est technique et qui sert surtout quand il y a des évolutions de cette fonction.
	nbzérof() = isa(nbzéro,Tuple) && nbzéro=nbzéro[1](nbzéro[2])
    noproblemo = sudf==sudokuAléatoireFini
	for tour in 1:nbtest
		sudini = sudf()
		nbzérof()
		sudaléa = sudokuAléatoire(nbzéro, fun=identity, matzéro=copy(sudini))
		# try 
		# 	résoutSudoku(sudaléa ; nbToursMax=tmax)
		# catch e
		# 	return ("bug", e, sudaléa)
		# end
		soluce = résoutSudoku(sudaléa ; nbToursMax=tmax)
		# if soluce[1] isa String
		if noproblemo && soluce[1] isa String
			## if noproblemo || soluce[1] != impossible[1]
			# if soluce[1] == impossible[1]
			# if soluce[1] == àcorriger[1]
				return (;sudzér = jsm(sudaléa), sudini, tour, nbzéro, soluce, tz="vieux($(jsm(sudaléa)))", ti="vieux($sudini)")
			# end
		elseif !isa(soluce[1],String) && !vérifSudokuBon(jsm(soluce[1]))
				return (;sudzér = jsm(sudaléa), sudini, tour, nbzéro, soluce, tz="vieux($(jsm(sudaléa)))", ti="vieux($sudini)")
		end
	end
	# return [[0,0,0,0,0,0,0,0,0],[0,2,3,0,0,0,1,5,0],[7,0,0,4,0,2,0,0,6],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,7,2,0,0,0,8,4,0],[0,1,4,0,0,0,7,9,0],[0,0,7,9,2,4,3,0,0],[0,0,0,1,5,7,0,0,0]], "Tout va bien… pour le moment 👍"
	return "Tout va bien… pour le moment 👍"
  end
  bt = testme = blindtest ## mini version =#
  ## btt = bt(); btt isa String ? md"# Top 😎" : vieux(btt[1])
  ## bbt = bt(sudf=salt); bbt isa String ? md"# Top 😎" : bbt[1]
  
#####################################################################################
#####################################################################################
#####################################################################################
#= begin #### BONUS du BONUS : pouvoir utiliser * sur les MD et Docs.HTML ^^
	# → https://discourse.julialang.org/t/concatenate-markdown-strings/59385
	# → https://github.com/JuliaLang/julia/blob/master/base/regex.jl#L759
	# https://github.com/JuliaLang/julia/blob/master/stdlib/Markdown/src/Common/
	import Base: *, ^
	# export *, ^
	ccat(c1, c2, ss=:no) = isfusionable(c1, c2, ss) ? fusion(c1, c2, ss) : vcat(c1,c2)
	*(m1::Markdown.MD, m2::Markdown.MD) = Markdown.MD(ccat(m1.content, m2.content))
	*(m::Markdown.MD, s::Union{AbstractChar, AbstractString, Docs.HTML}) = 
		Markdown.MD(ccat(m.content, parsebis(s).content, :right))
	*(s::Union{AbstractChar, AbstractString, Docs.HTML}, m::Markdown.MD) = 
		Markdown.MD(ccat(parsebis(s).content, m.content, :left))
	*(m::Markdown.MD) = m # avoids wrapping m in a useless subpattern (as Regex.jl)
	^(m::Markdown.MD, i::Int) = *(Markdown.MD(),fill(m,i)...)
 	
	isfusionable(c1, c2, stringside::Symbol) = 
		!isempty(c1) && !isempty(c2) && (similar(c1[end], c2[1]) || 
			(stringside == :right ? c2[1] isa Markdown.Paragraph : 
				(stringside == :left ? c1[end] isa Markdown.Paragraph : false)) )
	fusion(c1, c2, stringside::Symbol) = 
		vcat(c1[1:end-1], premerge(c1[end], c2[1], stringside), c2[2:end])
	
	similar(::Any, ::Any) = false # by default it is not similar
	similar(::Markdown.Paragraph, ::Markdown.Paragraph) = true # md"is " * md" good ?"
	similar(h1::Markdown.Header{l1}, h2::Markdown.Header{l2}) where {l1,l2} = (l1==l2)
	similar(c1::Markdown.Code, c2::Markdown.Code) = (c1.language == c2.language)
	similar(f1::Markdown.Footnote, f2::Markdown.Footnote) = (f1.id == f2.id)
	similar(::Markdown.BlockQuote, ::Markdown.BlockQuote) = true 
	similar(a1::Markdown.Admonition, a2::Markdown.Admonition) = 
		(a1.category == a2.category) && (a1.title == a2.title)
	similar(l1::Markdown.List,l2::Markdown.List) = 
		(l1.ordered == l2.ordered) && (l1.loose == l2.loose)
	
	prop(re::Any) = re # rest or other type, for ex. ::Docs.HTML
	prop(p::Union{Markdown.Paragraph, Markdown.BlockQuote, Markdown.Admonition}) = 
		p.content
	prop(h::Union{Markdown.Header, Markdown.Footnote}) = h.text
	prop(l::Markdown.Code) = l.code
	prop(l::Markdown.List) = l.items
	
	function premerge(c1, c2, ss) 
		if ss == :left && c1 isa Markdown.Paragraph
			if c2 isa Union{Markdown.Paragraph, Markdown.Header}
				merge(c2, prop(c1), prop(c2))
			elseif c2 isa Markdown.Code
				Markdown.Code(c2.language, hstring(Markdown.MD(c1), prop(c2)))
			else merge(c2, Any[Markdown.Paragraph(Any[prop(c1)])], prop(c2))
			end
		elseif ss == :right && c2 isa Markdown.Paragraph
			if c1 isa Union{Markdown.Paragraph, Markdown.Header}
				merge(c1, prop(c1), prop(c2))
			elseif c1 isa Markdown.Code
				Markdown.Code(c1.language, hstring(prop(c1), Markdown.MD(c2)))
			else merge(c1, prop(c1), Any[Markdown.Paragraph(Any[prop(c2)])])
			end
		else merge(c1, prop(c1), prop(c2))
		end
	end
	
	merge(::Any, hc, ac) = vcat(hc, ac) # for md"""$(html"that")"""
	merge(::Markdown.Paragraph, p1c, p2c) = Markdown.Paragraph(vcat(p1c, p2c))
	merge(::Markdown.Header{l}, h1t, h2t) where l = Markdown.Header{l}(vcat(h1t, h2t))
	merge(c::Markdown.Code, c1c, c2c) = Markdown.Code(c.language, *(c1c, c2c))
	merge(f::Markdown.Footnote, f1t, f2t) = Markdown.Footnote(f.id, ccat(f1t, f2t))
	merge(::Markdown.BlockQuote, b1c, b2c) = Markdown.BlockQuote(ccat(b1c, b2c))
	merge(a::Markdown.Admonition, a1c, a2c) = 
		Markdown.Admonition(a.category, a.title, ccat(a1c, a2c))
	merge(l::Markdown.List, l1i, l2i) = 
		Markdown.List(vcat(l1i, l2i), l.ordered, l.loose)
	
	parsebis(c::AbstractChar) = Markdown.MD(Markdown.Paragraph(Any[string(c)]))
	function parsebis(s::AbstractString)
		ps = Markdown.parse(s)
		if ps == Markdown.MD(Markdown.Code("", "")) || ps == Markdown.MD(Markdown.Paragraph([]))
			return Markdown.MD(Markdown.Paragraph(Any[" "]))
		else return ps
		end # avoids md" " → Code("","") or md"    " → Paragraph([]) but just " "
	end
	function parsebis(h::Docs.HTML)
		(isempty(h.content) || h.content == "") && return Markdown.MD()
		return Markdown.MD(Markdown.Paragraph(Any[h]))
	end
	function hstring(md1...)
		io = IOBuffer()
		print(io, md1...)
		return unescape_string(replace(String(take!(io)), r"""HTML{String}\(\"(.*)\"\)""" => s"\1"), '$')
	end
	*(h1::Docs.HTML{String}, h2::Docs.HTML{String}) = 
		Docs.HTML(*(h1.content, h2.content)) 
	*(h::Docs.HTML{String}, s::Union{AbstractChar, AbstractString}) = 
		Docs.HTML(*(h.content, s)) 
	*(s::Union{AbstractChar, AbstractString}, h::Docs.HTML{String}) = 
		Docs.HTML(*(s, h.content)) 
		# → https://github.com/JuliaLang/julia/blob/master/base/docs/utils.jl
		### Note from future : add this to Docs.Text (as Docs.HTML) ?
    
# begin #### Ancienne tentative simple mais non concluante #####################
	# import Base: *
	# function printNparse(md1, md2)
		# ioMD = IOBuffer()
		# print(ioMD, md1, md2)
		# return Markdown.parse(seekstart(ioMD))
	# end
	# *(md1::Markdown.MD, md2::Union{AbstractChar, AbstractString}) = printNparse(md1, md2)
	# *(md1::Union{AbstractChar, AbstractString, Markdown.MD}, md2::Markdown.MD) = printNparse(md1, md2)

	# *(md::Markdown.MD, h::Docs.HTML) = Markdown.MD(vcat(md.content, h))
	# *(h::Docs.HTML, md::Markdown.MD) = Markdown.MD(vcat(h, h.content))
	# *(h1::Docs.HTML{String}, h2::Docs.HTML{String}) = Docs.HTML(*(h1.content, h2.content))
	## Not good for md""" $(html"that") """
# end
end =#
end; nothing; # stylélàbasavecbonus! ## voir juste dans la cellule #Bonus au dessus ↑
# Voilà ! fin de la plupart du code de ce programme Plutoku.jl

# ╔═╡ abde0002-0001-0002-0001-0002dabe0001
md"## Résoudre un Sudoku par Alexis $cool" #= v1.8.7 vendredi 07/07/2023 🎲 

Pour la vue HTML et le style CSS, cela est inspiré du sudoku https://observablehq.com/@filipermlh/ia-sudoku-ple1
Pour le JavaScript, merci à (case suivante input) https://stackoverflow.com/a/15595732, (touches clavier) https://stackoverflow.com/a/44213036
Et bien sûr le calepin d'exemple de Fons "3. Interactivity"
Pour info, le code principal est stylélàbasavecbonus! ou plutôt caché juste après :)

Ce "plutoku" est visible sur : 
https://github.com/4LD/plutoku

Pour le relancer pour info : 
https://mybinder.org/v2/gh/fonsp/pluto-on-binder/HEAD?urlpath=pluto/open?url=https://raw.githubusercontent.com/4LD/plutoku/main/Plutoku.jl
Ou cf. https://github.com/fonsp/Pluto.jl et https://github.com/fonsp/pluto-on-binder : 
https://binder.plutojl.org/open?url=https:%252F%252Fraw.githubusercontent.com%252F4LD%252Fplutoku%252Fmain%252FPlutoku.jl 

=#

# ╔═╡ abde0003-0003-0003-0003-0003dabe0003
md"""Pour cette session, si besoin d'un : $(@bind boutonSudokuInitial html"<input type=button style='margin: 0 6px 0 6px' value='📷 instantané ;)'>") _(si sudoku vide → sudoku aléatoire)_"""

# ╔═╡ abde0004-0002-0004-0002-0004dabe0002
begin 
	boutonSudokuInitial # Remettre le puce "ModifierInit" sur Retour instantané ;)
	sudokuinitial!() # vieuxSudoku!(SudokuMémo[3]) Pour remplacer par celui modifié
	md""" $(@bind viderOupas puces(["Vider le sudoku initial","Retour instantané ;)"],"Retour instantané ;)"; idPuces="ModifierInit")) $(html" <a href='#Bonus' style='padding-left: 10px; border-left: 2px dotted var(--rule-color,#77777726);' >Bonus en bas ↓</a>") _: astuces + vieux!_"""
end

# ╔═╡ abde0005-0005-0005-0005-0005dabe0005
begin
	choixSudoku = (!isa(viderOupas, String) || viderOupas != "Vider le sudoku initial" ?  2  :  1  ) # Pour simplifier l'info du choix (explication nulle :)
	@bind bindJSudoku BondJamesBond(Sudini(SudokuMémo, choixSudoku), SudokuMémo[3])
end

# ╔═╡ abde0006-0004-0006-0004-0006dabe0004
begin 
	SudokuMémo[3] = bindJSudoku # Pour qu'il reste en mémoire → Retour instantané ;) 
	sudokuSolution = résoutSudoku(bindJSudoku) #;nbToursMax=0)# calcule la solution
	sudokuSolutionVue = sudokuSolution[1] # Le sudoku résolu (voir plus loin)
	sudokuSolution[2] # La petite explication seule : "Statistiques : ce programme…"
end ## mesurable avec # using BenchmarkTools; @benchmark résoutSudoku(bindJSudoku)

# ╔═╡ abde0007-0006-0007-0006-0007dabe0006
viderOupas; md"""#### $vaetvient Sudoku initial ⤴ (modifiable) et sa solution : $(html"</span>") """

# ╔═╡ abde0008-0007-0008-0007-0008dabe0007
md"""$(@bind voirOuPas BondJamesBond(puces(["🤫 Cachée", "En touchant, entrevoir les chiffres…", "Pour toutes les cases, voir les chiffres…"],"🤫 Cachée"; idPuces="CacherRésultat"), "🤫 Cachée") ) 

$(html"<div style='border-bottom: 2px dotted var(--rule-color,#777);'></div>")
                                                
$(@bind PropalOuSoluce BondJamesBond(puces(["…par chiffre", "…par case 🔢", "…par total (minimum = ✔)", "…de la solution 🚩"], "…par chiffre"; idPuces="PossiblesEtSolution", classe="pasla" ), "…par chiffre") ) 

$(html"<div id='divers' class='pasla' style='margin-top: 8px; margin-left: 1%; user-select: none; font-style: italic; font-weight: bold; color: #777'><span id='pucaroligne'><input type='checkbox' id='caroligne' name='caroligne'><label for='caroligne' style='margin-left: 2px;'>Caroligne ⚔</label></span>
<span id='puchoixàmettreenhaut' style='margin-left: 5%'><input type='checkbox' id='choixàmettreenhaut' name='choixàmettreenhaut'><label for='choixàmettreenhaut' style='margin-left: 2px;'>Cocher ici, puis toucher le chiffre à mettre dans le Sudoku initial</label></span></div>")"""

# ╔═╡ abde0009-0008-0009-0008-0009dabe0008
if !isa(voirOuPas, String) || voirOuPas == "🤫 Cachée"
	Markdown.parse( "###### 🤐 Cela est caché pour le moment comme demandé\n" * ( sudokuSolutionVue isa String ? "Malchance !" : "Bonne chance !" ) * 
" Si besoin, cocher `🤫 Cachée` pour revoir cette information : 

`En touchant, entrevoir les chiffres…` de chaque case…\\
_(petit truc : les chiffres en bleu réeffacent tout)_

   - `…par chiffre` et si possible : haut gauche = 1 au bas droite = 9 (centre de la case = 5)
   - `…par case 🔢` l'ensemble des chiffres possibles (de toute la case)
   - `…par total (minimum = ✔)` fait le compte et celle(s) avec ✔ (en place du 9) ont la somme minimale
   - seul `…de la solution 🚩` montre des chiffres du sudoku fini

On peut `Pour toutes les cases, voir les chiffres…` de la sous-catégorie choisie

Enfin, il y a deux options :  
`Caroligne ⚔` pour les cases liées (carré, colonne, ligne) ; \\
ou `Cocher ici, puis toucher le chiffre à mettre dans le Sudoku initial`" )
elseif PropalOuSoluce == "…de la solution 🚩" # || PropalOuSoluce isa Missing
		htmlSudoku(sudokuSolutionVue,bindJSudoku ; toutVoir= (voirOuPas=="Pour toutes les cases, voir les chiffres…") )
else htmlSudokuPropal(bindJSudoku,sudokuSolutionVue ; toutVoir= (voirOuPas=="Pour toutes les cases, voir les chiffres…"), parCase= (PropalOuSoluce =="…par case 🔢"), somme= (PropalOuSoluce=="…par total (minimum = ✔)"))
end

# ╔═╡ abde0010-0009-0010-0009-0010dabe0009
stylélàbasavecbonus = #= style CSS pour le sudokuHTML, le code principal est dans la cellule cachée tout en bas, juste après la cellule vide _`Enter cell code...`_" =# Docs.HTML(raw"""<style> /* Pour les boutons et 'code' */
	input[type="button" i] {
		background-color: #aaa;
		color: black;
		border: 2px outset #bbb;
		border-radius: 2px;}
	input[type="button" i]:hover,
	input[type="button" i]:active{
		background-color: #777;
		color: white;
		border: 2px solid #777;}
	// pluto-output.rich_output code {border: solid 1px #9b9f9f; /*/ contour fin /*/}
	pluto-output.rich_output code {border: solid 1px var(--rule-color,#77777726);}
/* autres bidouilles */
	#taide, #tesfoot, #va_et_vient {user-select: none;}
	#sudokufini, #copiefinie {cursor: pointer;} /*/ doigt et non souris /*/
	input[type="radio" i] {margin: 3px 3px 3px 0;}
	.pasla, .maistesou{ /* visibility: hidden; */ filter: opacity(62%) blur(2px);}
	tr#lignenonvisible {border-top: hidden;}
	pluto-cell:not(.show_input) > pluto-runarea .runcell {display: none;}
	/* pluto-cell:not(.show_input) > pluto-runarea, */
	/* #abde0009-0008-0009-0008-0009dabe0008 > pluto-runarea, */
	#abde0006-0004-0006-0004-0006dabe0004 > pluto-runarea {
	    display: block;
		background-color: unset;
	    opacity: 1;}
/* Pour le sudoku initial */
	table.sudokool {
		border: hidden;
		margin-block-start: 0;
		margin-block-end: 0;}
	table.sudokool tr {border:0;}
	table.sudokool tr.troisr {border-top: thick solid var(--cursor-color,#777);}
	table.sudokool tr td {
		border: 1px solid var(--cursor-color,#777); 
		padding: 0 !important;}
	table.sudokool tr td.troisd {border-left: thick solid var(--cursor-color, #777);}
	table.sudokool tr td input {
		text-align: center;
		font-size: 14pt;
		width: 100%;
		height: 100%;
		background-color: transparent;
		border:0;}
	table.sudokool tr td.damier{
		background-color: var(--rule-color,#77777726); } /* #777 ou #777777 adouci */
/* Pour le résultat ou aide */
	table.sudokool tr td {
		user-select: none;
		text-align: center;
		font-size: 14pt;
		width: 38px;
		height: 38px;}
	table.sudokool tr td.ini {
		font-weight: bold;
		color: var(--cm-var-color, #afb7d3);}
	table.sudokool tr td.ini.gris, 
	table.sudokoolmini td.vide.ini {
		font-style: italic;
		color: var(--cm-var-color, #afb7d3);}
	table.sudokool tr td.vide {color: var(--cm-property-color, #f99b15);}
	table.sudokool tr td.cachée {color: transparent;}
	table.sudokool tr td.gris {color: #777; font-style: italic;}
/*Pour le résultatmini ou aidemini*/
	table.sudokoolmini {
		border: hidden !important;
		margin-block-start: 0;
		margin-block-end: 0;}
	table.sudokoolmini tr,
	table.sudokoolmini tr td {border:0 !important;}
	table.sudokoolmini tr td {
		user-select: none;
		text-align: center;
		font-size: 7.49999pt;
		width: 12px;
		height: 11.67187px; 
			color: var(--cm-property-color, #f99b15);}
	table.sudokoolmini tr td.cachée {color: transparent;}
	table.sudokoolmini tr td.gris {color: #777; font-style: italic;}
</style>"""); pourvoirplutôt = Docs.HTML(raw"""<script>
// const plutôtstylé = `<link rel="stylesheet" href="./hide-ui.css"><style id="cachémoiplutôt">
const plutôtstylé = `<style id="cachémoiplutôt">
main {
    // margin-top: 20px;
    cursor: auto;
	margin: 0 !important;
    padding: 0 !important;
    // padding-bottom: 4rem !important;}
nav, header, preamble, pluto-cell:not(.show_input) > pluto-runarea .runcell,
body > header, preamble > button, pluto-cell > button, pluto-input > button,
footer, pluto-runarea, #helpbox-wrapper {
    display: none !important;}
pluto-shoulder {
	visibility:hidden;}
pluto-cell:not(.show_input) > pluto-runarea,
pluto-cell > pluto-runarea {
    display: block !important;
	background-color: unset;}

@media screen and (any-pointer: fine) {
    pluto-cell > pluto-runarea {
        // opacity: 0.5;
        opacity: 0; /* to make it feel smooth: */
        transition: opacity 0.25s ease-in-out;
    }
    pluto-cell > pluto-runarea > button:hover > span,
    pluto-cell:hover > pluto-runarea > span {
        // /* avant */ opacity: 1;
        opacity: 0.5; /* to make it feel snappy: */
        transition: opacity 0.05s ease-in-out;
    }
  //  pluto-cell > pluto-shoulder > button:hover {
  //      opacity: 0; /* to make it feel snappy: */
  //      transition: opacity 0.05s ease-in-out;
  //  } 
} 
</style>`;
function cooloupas() { 
	var BN = document.getElementById("BN");
	if (BN.innerHTML == "😉") { BN.innerHTML = "😎";} else { BN.innerHTML = "😉";};
};
// document.getElementById("BN")?.removeEventListener("click", cooloupas);
document.getElementById("BN")?.addEventListener("click", cooloupas);

var stylécaché = html`<span id='stylé'>${plutôtstylé}</span>`;
// var stylécaché = html`<span id='stylé'></span>`; // ancienne bidouille ////
""" * (plutôtvoir ? "var stylécaché = html`<span id='stylé'></span>`;" : "") * raw"""
function styléoupas() { 
	var stylé = document.getElementById("stylé");
	var cachémoiplutôt = document.getElementById("cachémoiplutôt");
	if (cachémoiplutôt) { 
		stylé.innerHTML = '';
	} else {
		stylé.innerHTML = plutôtstylé;
	};
};
document.getElementById("plutot").addEventListener("click", styléoupas);
return stylécaché;
</script>"""); calepin = Docs.HTML(raw"<script>return html`<a href=${document.URL.search('.html')>1 ? document.URL.replace('html', 'jl') : document.URL.replace('edit', 'notebookfile')} target='_blank' download>${document.title.replace('🎈 ','').replace('— Pluto.jl','')}</a>`;</script>"); caleweb = Docs.HTML(raw"<script>return html`<a href=${document.URL.search('.html')>1 ? document.URL : document.URL.replace('edit', 'notebookexport')} target='_blank' style='font-weight: normal;' download>HTML</a>`;</script>"); plutoojl = Docs.HTML(raw"<script>if (document.URL.search('.html')>1) {
	return html`<em>Pluto.jl</em>`
    } else { return html`<a href='./' target='_blank' style='font-weight: normal;'><em>Pluto</em></a><em>.jl</em>`}</script>"); pourgarderletemps = Docs.HTML(raw"""<script>function générateurDeCodeClé() {
	var copyText = document.getElementById("pour-définir-le-sudoku-initial");
	var pastext = document.getElementById("sudokincipit");
	copyText.value = 'vieuxSudoku!(' + pastext.getAttribute('sudata') + ')';
	copyText.select();
	navigator.clipboard.writeText(copyText.value); // document.execCommand("copy");
}
document.getElementById("clégén").addEventListener("click", générateurDeCodeClé);
	
var editCSS = document.createElement('style');
editCSS.id = "touslestemps";
var togglé = "0";

let touslestemps = document.getElementsByClassName("runtime");
// touslestemps.forEach( e => { // ne fonctionne pas :'(
for(let j=0; j<(Object.keys(touslestemps).length); j++){
	touslestemps[j].addEventListener("click", (e) => {
		// alert(e.target.classList.toggle("opaqueoupas"));
		var stylét = document.getElementById("touslestemps");
		togglé = (togglé=="0") ? "0.7" : "0" ;
		stylét.innerHTML = "pluto-cell > pluto-runarea { opacity: "+ togglé + "; }";
	});
};
return editCSS;
</script>"""); bonusetastuces = md"""$(html"<details open><summary style='list-style: none;'><h4 id='Bonus' style='margin-top: 17px; user-select: none;'>Bonus : le sudoku en cours pour plus tard…</h4></summary>") 
Je conseille de garder le code du sudoku en cours (en cliquant, la copie est automatique ✨) 
$(html"<input type=button id='clégén' value='Copier le code à garder :)'><input id='pour-définir-le-sudoku-initial' type='text' style='font-size: x-small; margin-right: 6px; max-width: 38px; background-color: var(--rule-color,#77777726); border: none; border-radius: 0 8px 8px 0; filter: opacity(89%);' />") **Note** : à coller ailleurs dans un bloc-notes par exemple 

##### …à retrouver comme d'autres vieux sudokus : 
Ensuite, dans une (nouvelle) session, cliquer dans _`Enter cell code...`_ tout en bas ↓ et coller le code qui fut gardé (cf. note ci-dessus).
Enfin, lancer le code avec le bouton ▷ tout à droite (qui clignote justement). 
Ce vieux sudoku est restoré en place du _Retour instantané !_ (cela [retourne en haut ↑](#ModifierInit)) 
	
$(html"<details class='pli' open><summary style='margin-bottom: -13px; list-style: none;'><h5 id='BonusAstuces' style='display:inline-block; user-select: none;'> Autres astuces :</h5></summary><style>details[open].pli > summary::after {content: ' (cliquer ici pour les cacher)'; font-style: italic;} details.pli > summary:not(details[open].pli > summary)::after {content: ' (cliquer ici pour les revoir)'; font-style: italic;} details.pli > summary:not(details[open].pli > summary){margin-bottom: 0 !important;}</style>")
   1. Modifier le premier sudoku (à vider si besoin, grâce au premier choix) et cocher ensuite ce que l'on souhaite voir comme **aide ou solution** ; le sudoku du dessous répond ainsi aux ordres. Cocher `🤫 Cachée` pour revoir des indications sur l'emploi des cases 
   2. Il est possible de bouger avec les flèches, aller à la ligne suivante automatiquement (à la _[Snake](https://www.google.com/search?q=Snake)_). Il y a aussi des raccourcis, comme `H` = haut, `V` ou `G` = gauche, `D` `J` `N` = droite, `B` = bas. Ni besoin de pavé numérique, ni d'appuyer sur _Majuscule_, les touches suivantes sont idendiques `1234 567 890` = `AZER TYU IOP` = `&é"' (-è _çà` 
   3. On peut **remonter la solution** au lieu du premier sudoku en cliquant sur le texte [Sudoku initial ⤴…](#va_et_vient) et pour revenir au sudoku initial modifiable [↪ Cliquer…](#lignenonvisible) sur le texte qui apparait juste en dessous 
   4. Pour information, la fonction **vieuxSudoku!**(), ou **vieux!**() ou **vs**(), sans paramètre permet de générer un sudoku aléatoire. En mettant un nombre, par exemple **vieuxSudoku!(62**) : ce sera le total de cases vides du sudoku aléatoire construit. Enfin, en mettant un intervalle, sous la forme **début : fin**, par exemple **vieux!**(**0:81**) : un nombre aléatoire dans cet intervalle sera utilisé. Pour les sudokus aléatoires, le fait de recliquer sur le bouton ▷ en génère un nouveau 
   5. Le code de ce programme en [_Julia_](https://fr.wikipedia.org/wiki/Julia_(langage_de_programmation)) est observable en cliquant d'abord sur $(html"<input type=button id='plutot' value='Ceci 📝🤓'>") pour basculer sur l'interface de $plutoojl, puis en cliquant sur l'œil 👁 à côté de chaque cellule. Il est aussi possible de télécharger ce calepin $calepin ou en $caleweb
$(html"</details></details>")
$pourvoirplutôt 
$stylélàbasavecbonus
$pourgarderletemps"""

# ╔═╡ abde0010-0010-0011-0010-0011dabe0010


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.3"
manifest_format = "2.0"
project_hash = "fa3e19418881bf344f5796e1504923a7c80ab1ed"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
"""

# ╔═╡ Cell order:
# ╟─abde0002-0001-0002-0001-0002dabe0001
# ╟─abde0004-0002-0004-0002-0004dabe0002
# ╟─abde0003-0003-0003-0003-0003dabe0003
# ╟─abde0006-0004-0006-0004-0006dabe0004
# ╟─abde0005-0005-0005-0005-0005dabe0005
# ╟─abde0007-0006-0007-0006-0007dabe0006
# ╟─abde0008-0007-0008-0007-0008dabe0007
# ╟─abde0009-0008-0009-0008-0009dabe0008
# ╟─abde0010-0009-0010-0009-0010dabe0009
# ╠═abde0010-0010-0011-0010-0011dabe0010
# ╟─abde0001-0011-0001-0011-0001dabe0011
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
