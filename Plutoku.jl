### A Pluto.jl notebook ###
# v0.19.32 ## Julia 1.9.3 

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

# ╔═╡ abde0001-0003-0001-0003-0001dabe0003
md"""Pour cette session, si besoin d'un : $(@bind instantané html"<input type=button style='margin: 0 6px 0 6px' value='📷 instantané ;)'>") _(si sudoku vide → sudoku aléatoire)_"""

# ╔═╡ abde0002-0010-0002-0010-0002dabe0010


# ╔═╡ abde0003-0011-0003-0011-0003dabe0011
begin 
	# stylélàbasavecbonus! ## ouvrir juste la cellule #Bonus au dessus ↑↑
	const plutôtvoir = false#||true # Plutôt voir l'interface de Pluto.jl (si true)
	const nbTmax = 81 # 0 # 81 par défaut : nb de tours max pour résoutSudoku
	# using Random: shuffle! # Astuce pour mixer, mais j'ai bidouillé avec jcvd ;)
	shuffle! = identity ## Si besoin, mais… Everyday I shuffling ! (dixit LMFAO)
	const àcorriger = "😜 Merci de corriger le Sudoku", md"""###### 😜 Merci de revoir le Sudoku modifiable, il n'est pas conforme : 
		En effet, il doit y avoir **un chiffre en double** au moins sur une ligne ou colonne ou carré 😄""" # Exemples de phrase en sortie, ne pas oublier…
	const impossible = "🧐 Sudoku faux et impossible", md"""###### 🧐 Sudoku faux et impossible à résoudre :
		Si ce n'est pas le cas, revérifier le Sudoku modifiable, car celui-ci n'a pas de solution""" # …que les retours à la ligne sont capricieux avec md""
	toutestbienquifinitbien(mS, nbChoixfait, nbToursTotal) = matriceàlisteJS(mS), md"**Statistiques :** ce programme fait _$nbChoixfait choix_ et **$nbToursTotal $((nbToursTotal>1) ? :tours : :tour)** pour résoudre ce sudoku"
    
    ## Je pensais mettre en lumière les id, mais je laisse pour le moment ainsi :)
	# const idBN = "BN" # 😉 ou 😎 tout en haut, à la base pour thème Blanc ou Noir
	const cool = html"<span id='BN' style='user-select: none;'>😎</span>" # 😉 ou 😎
	# const idpucinit = "ModifierInit" # id des premières puces
	# const idini = "sudokincipit" # id du premier sudoku ini = modifiable par défaut
	# const idfini = "sudokufini" # id du second sudoku fini = solution par défaut
	# const idshaut = "va_et_vient" # id entre les deux sudoku (phrase magique)
	# const idcopiefinie = "copiefinie" # id de la copie qui peut aller au dessus
	# const idtaide = "taide" # id de la table head si rien à montrer, ça t'aide ^^
	const idfoot = "tesfoot" # id de la table foot pour la copie, pas fou :P
	const footix = "document.getElementById(\"$idfoot\")?.dispatchEvent(new Event(\"click\"))" # le footer du sudoku modifiable (ajouter idini ?)
	# const idpucésultat = "CacherRésultat" # id des secondes puces /!\ à simplifier
	### PossiblesEtSolution, divers, pucaroligne, puchoixàmettreenhaut ### ↲ ###
	##### autres id à suppr ? si possible via une classe, préc. ou ordre #######
	## choixàmettreenhaut, caroligne
	## document.getElementById('choixàmettreenhaut')?.checked
	## document.getElementById('caroligne')?.checked
	### + d'autres idBonus que je garde en état pour touslestemps XP
	### Exemples : cachémoiplutôt, plutot, pour-définir-le-sudoku-initial, clégén…
	
	const set19 = Set(1:9) # Pour ne pas le recalculer à chaque fois
	jsvd() = fill(fill(0,9),9) # JSvide ou JCVD ^^ pseudo const
	jcvd() = (m=zeros(Int,9,9);m[rand(1:9),rand(1:9)]=rand(1:9);[m[:,i] for i in 1:9]) # JSvide mais pas vide, une fois
	adini() = [fill(0,9),fill(0,9),[0,1,2,3,4,5,0,0,0],[0,2,0,0,3,0,6,0,0],[0,3,4,5,6,0,0,7,0],[0,6,0,0,7,0,8,0,0],[0,7,0,0,8,9,0,0,0],fill(0,9),fill(0,9)] # Sudoku avec deux lettres… 

	SudokuMémo = [jsvd(), adini(),adini(),adini()] # garder mes initial(e)s ^^
	listeJSàmatrice(JSudoku::Vector{Vector{Int}}) = hcat(JSudoku...) #' en pinaillant
		jsm = listeJSàmatrice ## mini version (ou alias plus court si besoin)
	matriceàlisteJS(mat,d=9) = [mat[:,i] for i in 1:d] #I will be back! ## mat3 aussi
		mjs = matriceàlisteJS ## mini version
	### matriceàlisteJS(listeJSàmatrice(JSudoku)) == JSudoku ## Et inversement
	# nbcm(mat) = count(>(0), mat ) # Nombre de chiffres > 0 dans une matrice
	# nbcj(ljs) = count(>(0), listeJSàmatrice(ljs) ) # idem pour une liste JS
	kelcarré(i::Int,j::Int)::Int = 1+3*div(i-1,3)+div(j-1,3) # n° du carré du sudoku
	# carré(i::Int,j::Int)::Tuple{Int,Int}= 1+div(i-1,3)*3:3+div(i-1,3)*3, 1+div(j-1,3)*3:3+div(j-1,3)*3 # pour filtrer et ne regarder qu'un seul carré
	carr(i::Int)::UnitRange{Int}= 1+div(i-1,3)*3:3+div(i-1,3)*3 #filtre carr à moiti!
	# tuplecarré(ii::UnitRange{Int},jj::UnitRange{Int} #=,setij::Set{Tuple{Int,Int}}=#)= [(i,j) for i in ii, j in jj] #if (i,j) ∉ setij]
	# simplePossible(mat::Matrix{Int},i::Int,j::Int)::Set{Int}= setdiff(set19,view(mat,i,:), view(mat,:,j), view(mat,carr(i),carr(j)))
	
	struct BondJamesBond # BondDefault(element, default) ## pour Base.get() et @bind
		oo7 # element 	 		## Bond (à binder)
		vodkaMartini # default 	## un défaut ^^
	end # from https://github.com/fonsp/pluto-on-binder/pull/11
	Base.show(io::IO, m::MIME"text/html", bd::BondJamesBond) = 
		Base.show(io,m, bd.oo7) # oo7::HTML{String} vodkaMartini::Vector{Vector{Int}}
	Base.get(bd::BondJamesBond) = bd.vodkaMartini # évite Doctor No(thing ou missing)
	
	struct Case # une cellule du sudoku
		i::Int # ligne
		j::Int # colonne
		k::Int # karré
		ii::UnitRange{Int} # lignes dans ce karré
		jj::UnitRange{Int} # colonne dans ce karré
	end # Base.iterate(x::Case,i=1)=(i<=fieldcount(Case))?(getfield(x,i),i+1):nothing
	# Case() = Case(0,0,0,0:0,0:0) # Case(i::Int,j::Int,k::Int) = Case(i,j,k, carr(i),carr(j)) # Case(i::Int,j::Int) = Case(i,j,kelcarré(i,j),carr(i),carr(j))
	simPossible(mat::Matrix{Int}, c::Case)::Set{Int}= setdiff(set19,view(mat,c.i,:), view(mat,:,c.j), view(mat,c.ii,c.jj))
	chiPossible(mat::Matrix{Int}, c::Case, limp::Set{Int})::Set{Int}= setdiff(set19,limp,view(mat,c.i,:), view(mat,:,c.j), view(mat,c.ii,c.jj))
	
	mutable struct Sisenettoie # c'est donc ton …
		statut::Int # 1 à nettoyer, 2 et plus à prénettoyer
		const dernier::Case # dernière case vue
	end # Pour garder le compte par chiffre (1 = unique ; # = voir ex. uniclk!)
	struct Dicompte # Ensemble de dico pour compter chaque chiffre possible par…
		lig::Dict{Int, Dict{Int,Sisenettoie} } # ligne
		col::Dict{Int, Dict{Int,Sisenettoie} } # col…
		car::Dict{Int, Dict{Int,Sisenettoie} } 
		ful::Dict{Int, Set{Int}}	# fusible ligne
		fuc::Dict{Int, Set{Int}}	# déjà grillé (car sur plusieurs carrés)
		fuk::Dict{Int, Set{Int}}
	end
	Dicompte() = Dicompte((Dict{Int,Dict{Int,Sisenettoie}}() for _ in 1:3)..., (Dict{Int,Set{Int}}() for _ in 1:3)...)
	function getfun!(d::Dicompte, i::Int, j::Int, k::Int) # juste get! (func)
		get!(d.lig, i, Dict{Int,Sisenettoie}() )
		get!(d.col, j, Dict{Int,Sisenettoie}() )
		get!(d.car, k, Dict{Int,Sisenettoie}() )
		get!(d.ful, i, Set{Int}() )
		get!(d.fuc, j, Set{Int}() )
		get!(d.fuk, k, Set{Int}() )
	end
	
	struct Dicoréz # Ensemble de dico des cases vides (lesZéros) par…
		lig::Dict{Int, Set{Int}} # ligne
		col::Dict{Int, Set{Int}} # col…
		car::Dict{Int, Set{Tuple{Int,Int}}} 
	end
	Dicoréz() = Dicoréz(Dict{Int,Set{Int}}(),Dict{Int,Set{Int}}(),Dict{Int,Set{Tuple{Int,Int}}}()) # Base.deepcopy(d::Dicoréz) = Dicoréz(deepcopy(d.lig), deepcopy(d.col), deepcopy(d.car)) # Semble non utile
	function pushfun!(d::Dicoréz, i::Int, j::Int, k::Int)
		push!(get!(d.lig,i,Set{Int}() ), j)
		push!(get!(d.col,j,Set{Int}() ), i)
		push!(get!(d.car,k,Set{Tuple{Int,Int}}() ), (i,j) )
	end
	function deletefun!(d::Dicoréz, i::Int, j::Int, k::Int)
		delete!(d.lig[i], j)
		delete!(d.col[j], i)
		delete!(d.car[k], (i, j) )
	end # deletefun!(d::Dicoréz, c::Case) = deletefun!(d, c.i, c.j, c.k)
	
	struct Dicombo # Ensemble de dico des combinaisons de chiffre et leur place par…
		lig::Dict{ Int, Dict{Set{Int}, Set{Int}} } # ligne
		col::Dict{ Int, Dict{Set{Int}, Set{Int}} } # col…
		car::Dict{ Int, Dict{Set{Int}, Set{Tuple{Int,Int}}} }
	end
	Dicombo() = Dicombo(Dict{Int,Dict{Set{Int},Set{Int}}}(), Dict{Int,Dict{Set{Int},Set{Int}}}(), Dict{Int,Dict{Set{Int},Set{Tuple{Int,Int}}}}())
	
	struct Choix # choixAfaire
		c::Case 	# cas∙e à placer
		n::Int 		# nb de choix pris
		max::Int 	# nb d choix max
		rcl::Set{Int} # liste de choix restants
	end
	Choix()=Choix(Case(0,0,0,0:0,0:0),0,0,Set{Int}())
	
	function vérifSudokuBon(mat::Matrix{Int}) # Vérifie si le sudoku est réglo
		lignes = 	[Set{Int}() for _ in 1:9]
		colonnes = 	[Set{Int}() for _ in 1:9]
		carrés = 	[Set{Int}() for _ in 1:9]
		for j in 1:9, i in 1:9 # Pour tous les chiffres du sudoku
			chiffre = mat[i, j] # il doit n'en restera qu'un ! (par lig, col, car)
			if chiffre !=0 
				if chiffre in lignes[i] || chiffre in colonnes[j] || 
										   chiffre in carrés[kelcarré(i, j)]
					return false
				end
			push!(lignes[i], chiffre)
			push!(colonnes[j], chiffre)
			push!(carrés[kelcarré(i, j)], chiffre)
			end
		end
		return true # Le sudoku semble conforme (mais il peut être impossible 😜)
	end
	function ajoute(mat::Matrix{Int}, c::Case,i::Int,j::Int,k::Int, 
			n::Int,lesZérosàSuppr::Set{Case},dz::Dicoréz) # dans la matrice - zéro
		mat[i,j] = n # i,j,k = c.i,c.j,c.k
		push!(lesZérosàSuppr, c) # lesZérosàSuppr, zéro 
		deletefun!(dz, i,j,k) # Dicoréz
	end
	function nettoie(i::Int,j::Int,k::Int, n::Int, de::Dicompte) # on ne compte plus
		haskey(de.lig,i) && delete!(de.lig[i], n) # haskey utile
		haskey(de.col,j) && delete!(de.col[j], n) 
		haskey(de.car,k) && delete!(de.car[k], n) 
	end
	function sac!(nbs::Dicompte, c::Case, listepossibles::Set{Int}) # ÇACompte chaque chiffre possible (soit une fois, soit juste dans un carré, soit plus…)
	 i, j, k = c.i, c.j, c.k # (; i, j, k) = c # i, j, k = c si Base.iterate
	 getfun!(nbs, i, j, k)
	 for n in listepossibles
		n in nbs.ful[i] || if haskey(nbs.lig[i], n) # on regarde pour la ligne
			nbsin = nbs.lig[i][n]
			if nbsin.dernier.k == k
				nbsin.statut = 2 # karré à nettoyer pour le moment…
			else		# …finalement, rien à faire
				push!(nbs.ful[i], n) 
				delete!(nbs.lig[i], n)
			end
		else nbs.lig[i][n] = Sisenettoie(1,c) # top à ce moment…
		end
		n in nbs.fuc[j] || if haskey(nbs.col[j], n) # idem pour la colonne
			nbsjn = nbs.col[j][n]
			if nbsjn.dernier.k == k
				nbsjn.statut = 3 # karré à nettoyer pour le moment…
			else		# …finalement, rien à faire
				push!(nbs.fuc[j], n) 
				delete!(nbs.col[j], n)
			end
		else nbs.col[j][n] = Sisenettoie(1,c) # top à ce moment…
		end
		n in nbs.fuk[k] || if haskey(nbs.car[k], n) # idem pour le carré
			nbskn = nbs.car[k][n]
			if nbskn.dernier.i == i && nbskn.statut != 5
				nbskn.statut = 4 # ligne à nettoyer pour le moment…
			elseif nbskn.dernier.j == j && nbskn.statut != 4
				nbskn.statut = 5 # colonne à nettoyer pour le moment…
			else		# …finalement, rien à faire
				push!(nbs.fuk[k], n) 
				delete!(nbs.car[k], n)
			end
		else nbs.car[k][n] = Sisenettoie(1,c) # top à ce moment…
		end
	 end
	end
	function uniclk!(nbs::Dicompte, çaNavancePas::Bool, mat::Matrix{Int}, lesZérosàSuppr::Set{Case}, soréz::Dicoréz, dimp::Dict{Tuple{Int,Int}, Set{Int}}) #… voir si un chiffre est seul (ou uniquement sur une même ligne, col…). Car par exemple, s'il apparaît une seule fois sur la ligne : c'est qu'il ne peut qu'être là ^^
	# Autres exemple, si dans une ligne, il n'y a d'occurence que dans un des 3 carré : il ne pourra pas être ailleurs dans ce carré (que sur cette ligne)
	 for (i, nbsi) in nbs.lig # Pour les lignes
		for (n, nbsin) in nbsi 
			if nbsin.statut == 2 ## cf. autres ex plus haut, carré à nettoyer
				for (l, c) in setdiff(soréz.car[nbsin.dernier.k], ((i, c) for c in nbsin.dernier.jj))
					push!(get!(dimp,(l,c),Set{Int}() ), n)
				end
			else # if nbsin.statut == 1 ## l'unique, on le saura (≠ Sauron)
				j = nbsin.dernier.j
				k = nbsin.dernier.k
				n ∉ chiPossible(mat, nbsin.dernier, 
					get!(dimp,(i,j),Set{Int}())) && (return false) # pas 3a bol ^^
				ajoute(mat,nbsin.dernier, i, j, k, n, lesZérosàSuppr, soréz)
				haskey(nbs.col,j) && delete!(nbs.col[j], n) # nettoie(un peu)
				haskey(nbs.car,k) && delete!(nbs.car[k], n)
				çaNavancePas = false # Car on a réussi à remplir
			end
		end
	 end
	 for (j, nbsj) in nbs.col # Pour les colonnes
		for (n, nbsjn) in nbsj
			if nbsjn.statut == 3 
				for (l, c) in setdiff(soréz.car[nbsjn.dernier.k], ((l, j) for l in nbsjn.dernier.ii))
					push!(get!(dimp,(l,c),Set{Int}() ), n)
				end
			else # if nbsjn.statut == 1
				i = nbsjn.dernier.i
				k = nbsjn.dernier.k
				n ∉ chiPossible(mat, nbsjn.dernier, 
					get!(dimp,(i,j),Set{Int}())) && (return false) # pas 3b bol ^^
				ajoute(mat,nbsjn.dernier, i, j, k, n, lesZérosàSuppr, soréz)
				# haskey(nbs.lig,i) && delete!(nbs.lig[i], n) # déjà vu (ligne)
				haskey(nbs.car,k) && delete!(nbs.car[k], n)
				çaNavancePas = false # Car on a réussi à remplir
			end
		end
	 end
	 for (k, nbsk) in nbs.car # Pour les carrés
		for (n, nbskn) in nbsk
			i = nbskn.dernier.i
			j = nbskn.dernier.j
			if nbskn.statut == 4 
				for c in setdiff(soréz.lig[i], nbskn.dernier.jj)
					push!(get!(dimp,(i,c),Set{Int}() ), n)
				end
			elseif nbskn.statut == 5 
				for l in setdiff(soréz.col[j], nbskn.dernier.ii)
					push!(get!(dimp,(l,j),Set{Int}() ), n)
				end
			else # if nbskn.statut == 1
				n ∉ chiPossible(mat, nbskn.dernier, 
					get!(dimp,(i,j),Set{Int}())) && (return false) # pas 3c bol ^^
				ajoute(mat,nbskn.dernier, i, j, k, n, lesZérosàSuppr, soréz)
				# haskey(nbs.lig,i) && delete!(nbs.lig[i], n) # déjà vu (ligne)
				# haskey(nbs.col,j) && delete!(nbs.col[j], n) # déjà vu (colonne)
				çaNavancePas = false # Car on a réussi à remplir
			end
		end
	 end
	 return çaNavancePas
	end
	function pasAssezDePropal!(permu::Dicombo, c::Case, Nimp::Dict{Tuple{Int,Int}, Set{Int}}, soréz::Dicoréz, listepossibles::Set{Int}) 
	# Ici l'idée est de voir s'il y a plus chiffres à mettre que de cases : en regardant tout ! entre deux cases, trois cases… sur la ligne, colonne, carré ^^
	# Bref, s'il n'y a pas assez de propositions pour les chiffres à caser : c'est vrai
	# C'est pas faux : donc ça va. 
	# De plus, si un (ensemble de) chiffre est possible que sur certaines cellules, cela le retire du reste (en gardant via la matrice Nimp). Par exemple, sur une ligne, on a 1 à 8, la dernière cellule ne peut que être 9 -> grâce à Nimp, on retire le 9 des possibilités de toutes les cellules de la colonne, du carré (et de la ligne…) sauf pour cette dernière cellule justement ^^
	# Cela permet de limiter les possibilités pour éviter au mieux les culs de sac!
	# Etant quand-même un peu trop lourd, il faut l'utiliser que si besoin (c'est souvent utile :)
	 i, j, k = c.i, c.j, c.k # (; i, j, k) = c # i, j, k = c si Base.iterate
	 for (l,v) in collect(get!(permu.lig, i, Dict{Set{Int}, Set{Int}}())) # dili # Pour les lignes
		kk = union(l,listepossibles)
		if length(kk) > length(v)
			vv = union(v, Set(j), get(permu.lig[i], kk, Set{Int}() ) ) 
			if length(kk) == length(vv)
				# Les chiffres kk sont à retirer de toute la ligne sauf aux kk 
				for limp in setdiff(soréz.lig[i], vv)
					union!(get!(Nimp,(i,limp),Set{Int}() ), kk)
				end
			end
			permu.lig[i][kk] = vv
		else 
			return true
		end
	 end
	 for (l,v) in collect(get!(permu.col, j, Dict{Set{Int}, Set{Int}}())) # dicollect # Pour les colonnes
		kk = union(l,listepossibles)
		if length(kk) > length(v)
			vv = union(v, Set(i), get(permu.col[j], kk, Set{Int}() )) 
			if length(kk) == length(vv)
				# Les chiffres kk sont à retirer de toute la colonne sauf aux kk
				for limp in setdiff(soréz.col[j], vv)
					union!(get!(Nimp,(limp,j),Set{Int}() ), kk)
				end
			end
			permu.col[j][kk] = vv
		else 
			return true
		end
	 end
	 for (l,v) in collect(get!(permu.car, k, Dict{Set{Int}, Set{Tuple{Int,Int}} }())) # dica # Pour les carrés
		kk = union(l,listepossibles)
		if length(kk) > length(v)
			vv = union(v, Set([(i,j)]), get(permu.car[k], kk, Set{Tuple{Int,Int}}() ) ) 
			if length(kk) == length(vv)
				for (limp,ljmp) in setdiff(soréz.car[k], vv) #setcar,vv
					union!(get!(Nimp,(limp,ljmp),Set{Int}() ), kk)
				end
			end
			permu.car[k][kk] = vv
		else 
			return true
		end
	 end	
	 get!(permu.lig[i],listepossibles, Set( j ) )
	 get!(permu.col[j],listepossibles, Set( i ) )
	 get!(permu.car[k],listepossibles, Set( [(i,j)] ) )
	 return false
	end
	function puces(liste, valdéfaut=1 ; idPuces="p"*string(rand(Int)), classe="") # Permet de faire des puces en HTML pour faire un choix unique
	# Si "🤫 Cachée" cochée, cela floute les puces du dessous (PossiblesEtSolution)
		début = "<span id='$idPuces'" * (classe=="" ? ">" : "class='$classe'>")
		fin = "</span><script>const form = document.getElementById('$idPuces'); 
	const addClass=(id,classe)=>{document.getElementById(id).classList.add(classe)}
const removClass=(id,classe)=>{document.getElementById(id).classList.remove(classe)}
			form.oninput = (e) => { form.value = e.target.value; " *
		(idPuces=="CacherRésultat" ? raw"if (e.target.value=='🤫 Cachée') {
		addClass('PossiblesEtSolution', 'pasla'); addClass('divers', 'pasla')
			} else if (e.target.value=='Pour toutes les cases, voir les chiffres…') {
		addClass('pucaroligne', 'maistesou');
		removClass('PossiblesEtSolution', 'pasla'); removClass('divers', 'pasla')
			} else { removClass('PossiblesEtSolution', 'pasla'); removClass('divers', 'pasla'); removClass('pucaroligne', 'maistesou')
		}" : (idPuces=="PossiblesEtSolution" ? raw"if (e.target.value=='…par total (minima = ✔)') { addClass('puchoixàmettreenhaut', 'maistesou')
		} else { removClass('puchoixàmettreenhaut', 'maistesou')}" : "") ) * "}</script>"
		inputs = join(["<span style='display:inline-block; user-select: none;'><input type='radio' id='$idPuces$item' name='$idPuces' value='$item' style='padding: O 4px 0 4px;' $(item == liste[valdéfaut] && :checked )><label style='padding: 0 18px 0 4px;' for='$idPuces$item'>$item</label></span>" for item in liste])
		# inputs = join(["<span style='display:inline-block; user-select: none;'><input type='radio' id='$idPuces$item' name='$idPuces' value='$item' style='padding: O 4px 0 4px;' $(item == liste[valdéfaut] && :checked )><label style='padding: 0 18px 0 4px;' for='$idPuces$item'>$valeur</label></span>" for (item,valeur) in liste]) ### si liste::Vector{Pair{String,String}}
		return Docs.HTML(début * inputs * fin)
	end
	postpuce = Docs.HTML(raw"<div id='divers' class='pasla' style='margin-top: 8px; margin-left: 1%; user-select: none; font-style: italic; font-weight: bold; color: #777'><span id='pucaroligne'><input type='checkbox' id='caroligne' name='caroligne'><label for='caroligne' style='margin-left: 2px;'>Caroligne ⚔</label></span><span id='puchoixàmettreenhaut' style='margin-left: 5%'><input type='checkbox' id='choixàmettreenhaut' name='choixàmettreenhaut'><label for='choixàmettreenhaut' style='margin-left: 2px;'>Cocher ici, puis toucher le chiffre à mettre dans le Sudoku initial</label></span></div>")
	vaetvient = Docs.HTML(raw"<script> var vieillecopie = false;
	function déjàvu() { 
		let père = document.getElementById('sudokincipit').parentElement;
		let fils = document.getElementById('copiefinie');
		let ancien = document.getElementById('sudokufini');
		if (vieillecopie.isEqualNode(ancien)) {
			ancien.innerHTML = fils.innerHTML;
			ancien.removeChild(ancien.querySelector('tfoot'));
			msga(ancien) }
		document.getElementById('sudokincipit').hidden = false;
		père.removeChild(fils);
		document.getElementById('va_et_vient').textContent = `Sudoku initial ⤴ (modifiable) et sa solution : ` }
	function làhaut() { 
		let père = document.getElementById('sudokincipit').parentElement;
		let fils = document.getElementById('copiefinie');
		let copie = document.getElementById('sudokufini');
		fils ? père.removeChild( fils ) : true;
		document.getElementById('sudokincipit').hidden = true;
		const tabl = document.createElement('table');
		vieillecopie = (copie ? copie.cloneNode(true) : tabl);
		tabl.id = 'copiefinie';
		tabl.classList.add('sudokool');
		tabl.innerHTML = (copie ? copie.innerHTML : `<thead id='taide'><tr><td style='text-align: center;width: 340px;padding: 26px 0;border: 0;'>Rien à montrer, c'est coché  <code>🤫 Cachée</code></td></tr></thead>`) + `<tfoot id='tesfoot'><tr id='lignenonvisible'><th colspan='9'>↪ Cliquer ici pour revenir au sudoku modifiable</th></tr></tfoot>`;
		père.appendChild(tabl);
		document.getElementById('taide')?.addEventListener('click', déjàvu);
		document.getElementById('tesfoot').addEventListener('click', déjàvu);
		copie ? msga(document.getElementById('copiefinie')) : true;
		document.getElementById('va_et_vient').textContent = `Solution ↑ (au lieu du sudoku modifiable initial)` }
	document.getElementById('va_et_vient').addEventListener('click', làhaut);</script><span id='va_et_vient'>") # Pour le texte entre les deux sudoku (initaux et solution). Cela permet de remonter la solution en cliquant dessus
	function interval(args... ; val= isempty(args) ? 1 : args[1], mini=val, maxi=mini+10, x="")
		v,mi,ma,xx = args..., false, false, false, false
		maj(x,t) = (t===false ? x : t)
		val,mini,maxi,x = maj(val,v), maj(mini,mi), maj(maxi,ma), maj(x,xx)
		Docs.HTML("<input type='range' min='$mini' max='$maxi' value='$val' oninput='this.nextElementSibling.value=`$x=`+this.value;'/><output style='display:inline-block;width:$((length(x)+ceil(Int,log10(maxi)))÷2)em;margin:0 4px;'>$x=$val</output>") # slider PlutoUI
	end
	# interval(mini=1,maxi=1,val=maxi; id=string(rand(Int))) = Docs.HTML("<input type='range' min='$mini' max='$maxi' value='$val' id='i$id' oninput='this.nextElementSibling.value=this.value;'/><input type='number' min='$mini' max='$maxi' value='$val' id='o$id' oninput='this.previousElementSibling.value=this.value;'/>") # slider bof inputBis
	macro nombre(nb=:nb,val=59,mini=0,maxi=81) # slider++
		x = string(nb) # macro nom(arg);string(arg);end
		:(@bind $nb $(BondJamesBond(interval(;val,mini,maxi,x), val)) )
	end
	
	sudini(mémo, choix) = Docs.HTML("<script> // stylélàbasavecbonus!
	const premier = JSON.stringify( $(mémo[1]) ); // sudoku vide
	const deuxième = JSON.stringify( $(mémo[2]) ); // sudoku mémo instantané ;)
	const zéroku = $(mémo[isa(choix, String) && choix == "Vider le sudoku initial" ? 1 : 2])" * raw" // const zéroku = [[0,0,0,7,0,0,0,0,0],[1,0,0,0,0,0,0,0,0],[0,0,0,4,3,0,2,0,0],[0,0,0,0,0,0,0,0,6],[0,0,0,5,0,9,0,0,0],[0,0,0,0,0,0,4,1,8],[0,0,0,0,8,1,0,0,0],[0,0,2,0,0,0,0,5,0],[0,4,0,0,0,0,3,0,0]];
			
	window.createsudini = (values) => {
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
		  const isDroite = j%3 === 0;
		  const isGris = (Math.floor(i/3)+Math.floor(j/3))%2 !== 0; // fond en damier
		  const classoupas = isGris ? (isDroite?`class='damier troisd'`:`class='damier'`) : (isDroite?`class='troisd'`:``);
		  const htmlCell = html`<td ${classoupas}>${htmlInput}</td>`
		  data[i][j] = value||0;
		  htmlRow.push(htmlCell) }
		const isDroiteBis = i%3 === 0 ? `class='troisr'` : ``;
		htmlData.push(html`<tr ${isDroiteBis}>${htmlRow}</tr>`) }
	  const _sudoku = html`<table id='sudokincipit' sudata=${JSON.stringify(data)} class='sudokool'><tbody>${htmlData}</tbody></table>`  
	return {_sudoku,data} }
	
	window.makesudiniReactive = ({_sudoku:html, data}) => { 
	  html.addEventListener('input', (e)=>{
		e.stopPropagation(); e.preventDefault(); 
		html.value = data;
		return false;
	  }); 
	  
	  const puCHECKetMATdispatchEvent = () => {
		// Efface les puces car cela a été touché
		const ele = document.getElementsByName('ModifierInit');
		for(let ni=0;ni<ele?.length;ni++)
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
	  html.querySelectorAll('input').forEach(input => { 
		const daligne = ({target}) => target.dataset.row;
		const dacol = ({target}) => target.dataset.col;
		const etp2 = ({target}) => target.parentElement.parentElement;
		const etp3 = ({target}) => target.parentElement.parentElement.parentElement;
	
		const moveDown = (e) => { /* case juste en dessous, ou tout en haut */
			(etp2(e).nextElementSibling == null) ? etp3(e).firstChild.childNodes[dacol(e)].firstChild.focus() : etp2(e).nextElementSibling.childNodes[dacol(e)].firstChild.focus() }
		const moveUp = (e) => { /* case juste en dessus, ou tout en bas */
			(etp2(e).previousElementSibling == null) ? etp3(e).lastChild.childNodes[dacol(e)].firstChild.focus() : etp2(e).previousElementSibling.childNodes[dacol(e)].firstChild.focus() }
		const moveLeft = (e) => { /* case juste avant, ou dernière de la ligne */
			if (e.target.parentElement.previousElementSibling == null) { 
				(etp2(e).previousElementSibling == null) ? etp3(e).lastChild.lastChild.firstChild.focus() : etp2(e).previousElementSibling.lastChild.firstChild.focus();
			} else { e.target.parentElement.previousElementSibling.firstChild.focus()} }
		const moveRight = (e) => { /* case juste après, ou première de la ligne */
			if (e.target.parentElement.nextElementSibling == null) {
				(etp2(e).nextElementSibling == null) ? etp3(e).firstChild.firstChild.firstChild.focus() : etp2(e).nextElementSibling.firstChild.firstChild.focus();
			} else {e.target.parentElement.nextElementSibling.firstChild.focus()} }
		
		input.addEventListener('keydown',(e) => {
		  e.target.select(); // mieux que focus
			
		  switch (e.key) {
			case 'ArrowDown':
				moveDown(e); break; 
			case 'ArrowUp':
				moveUp(e); break; 
			case 'ArrowLeft':
				moveLeft(e); break; 
			case 'ArrowRight':
				moveRight(e); break; 
			case 'Shift':
			case 'CapsLock':
			case 'NumLock':
				break; // https://www.w3.org/TR/uievents-key/#keys-modifier
			case 'Backspace':
			case 'Delete':
				if (data[daligne(e)][dacol(e)] !== 0) {
					data[daligne(e)][dacol(e)] = 0;
					e.target.value = '';
					puCHECKetMATdispatchEvent() }
				(e.key==='Delete')?moveRight(e):moveLeft(e);
				const da = document.activeElement; (e.key==='Delete')?(da.selectionStart = da.selectionEnd = da.value.length):(da.selectionStart = da.selectionEnd = 0); //select KO :(
				break;
			default:
				return } }) 
			
		const màjValeur = (e) => {
		  const i = e.target.dataset.row; // daligne(e)
		  const j = e.target.dataset.col; // dacol(e)
		  const val = e.target.value; //parseInt(e.target.value);
		  const oldata = data[i][j];
		  const bidouilliste = {a:1,z:2,e:3,r:4,t:5,y:6,u:7,i:8,o:9,
			A:1,Z:2,E:3,R:4,T:5,Y:6,U:7,I:8,O:9,
			'\&':1,é:2,'\"':3,\"\'\":4,'\(':5,'\-':6,è:7,_:8,ç:9,
			'§':6,'!':8,	q:1,Q:1, w:2,W:2};
		  
		  if (val in bidouilliste) {
			e.target.value = data[i][j] = bidouilliste[val];
		  } else if (val <= 9 && val >=1) {
			data[i][j] = parseInt(val);
		  } else if ((val == 0)||(val == 'à')||(val == 'p')||(val == 'P')) {
			data[i][j] = 0;
			e.target.value = '';
		  } else { e.target.value = data[i][j] === 0 ? '' : data[i][j] }
		  
		  if (oldata === data[i][j]) {
			e.stopPropagation(); e.preventDefault(); 
		  } else {
			puCHECKetMATdispatchEvent()  } }
		const màjEtBouge = (e) => {
		  const val = e.target.value;
		  màjValeur(e);
		  const androidChromeEstChiant = {'b':moveDown,'B':moveDown,
			'h':moveUp,'H':moveUp,	'j':moveRight,'J':moveRight,
			'g':moveLeft,'G':moveLeft,'v':moveLeft,'V':moveLeft,
			'd':moveRight,'D':moveRight,'n':moveRight,'N':moveRight};
		  (val in androidChromeEstChiant) ? androidChromeEstChiant[val](e) : moveRight(e);
		  document.activeElement?.select() }
		
		input.addEventListener('input', màjEtBouge); // mis à jour avec clavier
		input.addEventListener('ctop', màjValeur)  }) // chiffre à modifier en haut
	  
	  puCHECKetMATdispatchEvent();
	  return html }
	
	return makesudiniReactive(createsudini(zéroku));
	</script>")
	function sudfini(JSudokuFini::Union{String, Vector{Vector{Int}}}=jsvd(),JSudokuini::Union{String, Vector{Vector{Int}}}=jsvd(); toutVoir::Bool=true)
	# Pour sortir de la matrice (conversion en tableau en HTML) du sudoku
	# Le JSudokuini permet de mettre les chiffres en bleu (savoir d'où l'on vient)
	# Enfin, on peut choisir de voir petit à petit en cliquant ou toutVoir d'un coup
	### if isa(JSudokuFini, String)… avait un bug d'affichage pour le reste du code…
		return isa(JSudokuFini, String) ? Docs.HTML("<h5 style='text-align: center;margin-bottom: 6px;user-select: none;' onclick='$footix'> ⚡ Attention, sudoku initial à revoir ! </h5><table id='sudokufini' class='sudokool' style='user-select: none;' <tbody><tr><td style='text-align: center;width: 340px;' onclick='$footix'>$JSudokuFini</td></tr></tbody></table>") : Docs.HTML(raw"<script id='scriptfini'> //stylélàbasavecbonus!
		const kelcar = (i, j) => 3 *Math.floor(i/3) + Math.floor(j/3);
		
		const createsudfini = (values, values_ini) => {	
		  const data = [];
		  const htmlData = [];
		  for(let i=0; i<9;i++){
			let htmlRow = [];
			data.push([]);
			for(let j=0; j<9;j++){
			  const valuesLine = values[i];
			  const value = valuesLine?valuesLine[j]:0;
			  const isInitial = values_ini[i][j]>0;
			  const isDroite = j%3 === 0 ? ' troisd' : '';
			  const htmlCell = html`<td class=\"" * (toutVoir ? raw"${isInitial?'ini':'vide'}" : raw"${isInitial?'ini':'vide cachée'}") * raw"${isDroite}\" data-row='${i}' data-col='${j}' data-car='${kelcar(i,j)}'>${(value||' ')}</td>`;
			  data[i][j] = value||0;
			  htmlRow.push(htmlCell) }
			const isDroiteBis = i%3 === 0 ? `class='troisr'` : ``;
			htmlData.push(html`<tr ${isDroiteBis}>${htmlRow}</tr>`) }
		  const _sudoku = html`<table id='sudokufini' " * (toutVoir ? raw" " : raw"style='user-select: none;' ") * raw"class='sudokool'><tbody>${htmlData}</tbody></table>`  // return {_sudoku,data}
		  /* const jdataini = JSON.stringify(values_ini);
		  const jdataFini = JSON.stringify(values);
		  _sudoku.setAttribute('sudataini', jdataini);
		  _sudoku.setAttribute('sudatafini', jdataFini);
		  const sudokuiniàvérif = document.getElementById('sudokincipit');
		  if (sudokuiniàvérif && sudokuiniàvérif.getAttribute('sudata') !=jdataini) {
			return html`<h5 style='text-align: center;user-select: none;'>🚀 Recalcul rapide ;)</h5>` } // barre de chargement ^^  */
		return _sudoku }
		
		window.msga = (_sudoku) => { // msga=MakeSudokuGreat&reactiveAgain !!!
		  
		  const upme = (target) => { 
			if (document.getElementById('choixàmettreenhaut')?.checked) {
			const { row, col } = target.dataset;
			const lign = parseInt(row) + 1; const colo = parseInt(col) + 1;
			const vale = target.textContent;
			const cible = document.querySelector(`#sudokincipit > tbody > tr:nth-child(${lign}) >  td:nth-child(${colo}) > input[type=text]`);
			if (!isNaN(vale)) {
				cible.value = cible.value==vale ? 0 : vale ; 
				if (cible.value==0) {target.classList.remove('ini');target.addEventListener('click', videactiv);target.removeEventListener('click', upmee)"* (toutVoir ? raw"" : ";target.removeEventListener('click', bleucache)") * "} else {target.classList.add('ini');target.removeEventListener('click', videactiv);target.addEventListener('click', upmee)"* (toutVoir ? raw"" : "; target.addEventListener('click', bleucache)")* "}; // ini gris ou bleu
				target.classList.remove('cachée');
				target.classList.add('gris'); 
			// document.getElementById('tesfoot')?.dispatchEvent(new Event('click'));
				cible.dispatchEvent(new Event('ctop')) } }};
		  const upmee = ({target}) => {upme(target)};
		  
		  const tdbleus = _sudoku.querySelectorAll('td.ini');
		  tdbleus.forEach(tdble => { tdble.addEventListener('click', upmee)});
		  
		  const videactiv = ({target}) => {
					upme(target); " * (toutVoir ? raw"};" : 
			raw" if (document.getElementById('caroligne')?.checked) {	
					const { row, col, car } = target.dataset;
					const grantb = target.parentElement.parentElement.querySelectorAll(`td.vide[data-row='${row}'], td.vide[data-col='${col}'], td.vide[data-car='${car}']`); // target.closest('tbody');
					grantb.forEach((tdf) => {
					  tdf.classList.remove('cachée') }) // ciel gris
				} else { target.classList.toggle('cachée') }
		  	} 
		  const bleucache = ({target}) => {
			if (!(document.getElementById('choixàmettreenhaut')?.checked)) {target.parentElement.parentElement.querySelectorAll('td:not(.ini)').forEach((cell) => {cell.classList.add('cachée') }) }}
		  tdbleus.forEach(tdble => { tdble.addEventListener('click', bleucache)  })  ") * "
		  let tds = _sudoku.querySelectorAll('td.vide');
		  tds.forEach(td => {td.addEventListener('click', videactiv)});
		  return _sudoku }   // sinon : return createsudfini(…)._sudoku
		
		return msga(createsudfini($JSudokuFini, $JSudokuini) );	</script>") #String
	end
	htmls = sudfini ## mini version (ou alias plus court si besoin)
	htmat = sudfini ∘ matriceàlisteJS ## mini version 

	const pt1 = "·" # "." ## Caractères de remplissage pour mieux voir le nbPropal
	const pt2 = "◌" # "○" # "◘" # "-" # ":"
	const pt3 = "●" # "■" # "▬" # "—" # "⁖" # "⫶"
	function chiffrePropal(mat::Matrix{Int},c::Case,mImp::Dict{Tuple{Int,Int}, Set{Int}},vide::Bool) # Remplit une case avec tous ses chiffres possibles, en mettant le 1 en haut à gauche et le 9 en bas à droite (le 5 est donc au centre). S'il n'y a aucune possibilité, on remplit tout avec des caractères bizarres ‽
	# Pour mise en forme en HTML mat3 : 3x3 (une matrice de 3 lignes et 3 colonnes)
		cp = (mat[c.i,c.j] == 0 ? 
			chiPossible(mat,c,get!(mImp,(c.i,c.j),Set{Int}())) : mat[c.i,c.j])
		if isempty(cp)
			return [["◜","‽","◝"],["¡","/","!"],["◟","_","◞"]]
			# return [["⨯","⨯","⨯"],["⨯","⨯","⨯"],["⨯","⨯","⨯"]]
		end
		# lcp = length(cp)
		# vi = (vide ? " " : (lcp<4 ? pt1 : (lcp<7 ? pt2 : pt3)))
		vi = (vide ? " " : pt1) #"◦") # "⨯") # pt1) ## retour à pt1 "·" ^^
		return matriceàlisteJS(reshape([((x in cp) ? string(x) : vi) for x in 1:9], (3,3)),3)
	end
	function nbPropal(mat::Matrix{Int},c::Case,mImp::Dict{Tuple{Int,Int},Set{Int}}) # Assez proche de chiffrePropal ci-dessus, mais ne montre pas les chiffres possibles. Cela montre le nombres de chiffres possibles, en remplissant petit à petit avec pt1 à pt3 suivant.
	# Pour mise en forme en HTML mat3 : 3x3
		lcp = (mat[c.i,c.j] == 0 ? 
			length(chiPossible(mat,c,get!(mImp,(c.i,c.j),Set{Int}()))) : 1)
		if lcp == 0
			return [["↘","↓","↙"],["→","0","←"],["↗","↑","↖"]], 0
		else
			return matriceàlisteJS(reshape([(x == lcp ? string(x) : (x<lcp ? (lcp<4 ? pt1 : (lcp<7 ? pt2 : pt3)) : " ")) for x in 1:9], (3,3)),3), lcp
		end
	end
	function sudpropal(JSudokuini::Union{String, Vector{Vector{Int}}}=jsvd(),JSudokuFini::Union{String, Vector{Vector{Int}}}=jsvd() ; toutVoir::Bool=true, parCase::Bool=true, somme::Bool=true)
	# Assez proche de sudfini, mais n'a pas besoin d'avoir un sudoku résolu en entrée. En effet, il ne montre que les chiffres (ou leur nombre = somme) possibles pour le moment.
	# Il y a plusieurs cas : (cela est peutêtre à changer)
		# toutVoir ou non : découvre tous les cellules si toutVoir (sinon à cliquer)
		# parCase : découvre une celle cellule (sinon plusieurs)
		# somme : voir juste le nombre de possibilité, sinon, voir les possibilités
		mS::Matrix{Int} = listeJSàmatrice(JSudokuini)
		lesZéros = Set{Case}()
		dicoréz = Dicoréz()
		for j in 1:9, i in 1:9 if mS[i,j]==0
				k = kelcarré(i,j)
				push!(lesZéros, Case(i,j,k,carr(i),carr(j)) )
				pushfun!(dicoréz, i, j, k)
		end end 
		lesZérosIni = copy(lesZéros) 
		mImp = Dict{Tuple{Int,Int}, Set{Int}}()
		lesZérosàSuppr=Set{Case}()
		while !isempty(lesZéros) ## for whiile in 1:2
			dicompte = Dicompte()
			dicombo = Dicombo()
			for zéro in lesZéros
				listechiffre = chiPossible(mS,zéro,get!(mImp,(zéro.i,zéro.j),Set{Int}() ) ) 
				sac!(dicompte, zéro, listechiffre)
				if isempty(listechiffre) || pasAssezDePropal!(dicombo, zéro, mImp, dicoréz, listechiffre)
					empty!(lesZérosàSuppr) ## Non utile
					break
				elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
					i,j,k = zéro.i,zéro.j,zéro.k
					pos=pop!(collect(listechiffre)) # le Set en liste
					ajoute(mS,zéro,i,j,k,pos,lesZérosàSuppr,dicoréz)
					nettoie(i,j,k,pos,dicompte)
				end
			end
			uniclk!(dicompte,true,mS,lesZérosàSuppr,dicoréz,mImp)
			isempty(lesZérosàSuppr) && break
			setdiff!(lesZéros, lesZérosàSuppr) # On retire ceux remplis 
			empty!(lesZérosàSuppr)
		end 
		mPropal = fill(fill( fill("0",3),3) , (9,9) )
		if somme	
			mine = 10
			grisemine = Tuple{Int,Int}[]
			for z in lesZérosIni
				i,j = z.i, z.j
				mPropal[i,j], lcp = nbPropal(mS, z, mImp)
				if lcp < mine
					mine = lcp
					grisemine = [(i,j)]
				elseif lcp == mine
					push!(grisemine, (i,j))
				end
			end
			parCase = toutVoir # bidouille à changer ?
			toutVoir = true
			if 0 < mine < 9
				for (i,j) in grisemine
					mPropal[i,j][3][3] = "✔"
				end
			end
		else
			for z in lesZérosIni
				mPropal[z.i,z.j] = chiffrePropal(mS, z, mImp, parCase)
			end
		end
		JPropal = matriceàlisteJS(mPropal)
			
		return Docs.HTML(raw"<script id='scriptfini'> // stylélàbasavecbonus!
		const kelcar = (i, j) => 3 *Math.floor(i/3) + Math.floor(j/3);
		
		const createsudpropal = (mvalues, values_ini) => {	
		  const data = [];  const htmlData = [];
		  for(let i=0; i<9;i++){
			let htmlRow = [];  data.push([]);
			for(let j=0; j<9;j++){
				const htmlMiniData = [];
				const isInitial = values_ini[i][j]>0;
				var mini_sudoku = values_ini[i][j];
				if (!(isInitial)) {
				  for(let pi=0; pi<3;pi++){
					let htmlMiniRow = [];
					for(let pj=0; pj<3;pj++){
						const miniValue = mvalues[i][j][pi][pj];
						const htmlMiniCell = html`<td class=\"mini"*(toutVoir && parCase ? "\"" : raw"${isInitial?' prop':' vide cachée'}\" ")*raw" data-row='${pi}' data-col='${pj}' data-car='${kelcar(pi,pj)}'>${(miniValue||' ')}</td>`; 
						htmlMiniRow.push(htmlMiniCell) }
					htmlMiniData.push(html`<tr style='border-style: none !important;'>${htmlMiniRow}</tr>`) }
				var mini_sudoku = html`<table class='sudokoolmini' style='user-select: none;'><tbody>${htmlMiniData}</tbody></table>` }
			  const valuee = mini_sudoku;
			  const isDroite = j%3 === 0 ? ` troisd` : ``;
			  const htmlCell = html`<td class=\"${isInitial?'ini':'props'} ${isDroite}\" data-row='${i}' data-col='${j}' data-car='${kelcar(i,j)}'>${(valuee||' ')}</td>`;
			  data[i][j] = valuee||0;
			  htmlRow.push(htmlCell) }
			const isDroiteBis = i%3 === 0 ? `class='troisr'` : ``;
			htmlData.push(html`<tr ${isDroiteBis}>${htmlRow}</tr>`)}
		  const _sudoku = html`" * (isa(JSudokuFini, String) ? "<h5 style='text-align: center;user-select: none;' onclick='$footix'> ⚡ Attention, sudoku initial à revoir ! </h5>" : "") * raw"<table id='sudokufini' class='sudokool' style='user-select: none;'><tbody>${htmlData}</tbody></table>`  
		  /* const jdataini = JSON.stringify(values_ini);
		  _sudoku.setAttribute('sudataini', jdataini);
		  _sudoku.setAttribute('sudatafini', JSON.stringify(mvalues)); // jdataFini
		  const sudokuiniàvérif = document.getElementById('sudokincipit');
		  if (sudokuiniàvérif?.getAttribute('sudata') != jdataini) {
			return html`<h5 style='text-align: center;user-select: none;'>🚀 Recalcul rapide ;)</h5>` } */
		  return _sudoku }
		
		window.msga = (_sudoku) => { // msga=MakeSudokuGreat&reactiveAgain !!! 
		  const justeremonte = (tdmini) => { // 3 et 2+3
			"*(somme ? raw"/* Somme/total donc rien à remonter ^^ */ " : raw"
			tdmini.forEach(td => {
				td.addEventListener('click', ({target}) => {
					if (document.getElementById('choixàmettreenhaut')?.checked) {
						const { row, col } = target.parentElement.parentElement.parentElement.parentElement.dataset;
						const lign = parseInt(row) + 1; // 3 et 2+3
						const colo = parseInt(col) + 1;
						const vale = target.textContent; // NaN → pas besoin
						const cible = document.querySelector(`#sudokincipit > tbody > tr:nth-child(${lign}) >  td:nth-child(${colo}) > input[type=text]`);
						if (!(isNaN(vale))) {
							cible.value = cible.value == vale ? 0 : vale ; 
							target.parentElement.parentElement.querySelectorAll('td.ini').forEach(td => {td.classList.remove('ini')});
							cible.value==0 ? target.classList.remove('ini') : target.classList.add('ini'); // ini gris ou bleu
							target.classList.add('gris'); 
							// document.getElementById('tesfoot')?.dispatchEvent(new Event('click'));
							cible.dispatchEvent(new Event('ctop')) }}  })})")*raw"}
		  
		  const carolign = ({target}) => { // 3 et 1… à la base
			const { row, col, car } = target.parentElement.parentElement.parentElement.parentElement.dataset;
			const { row:ilig, col:jcol } = target.dataset;
			const minj = `td.vide[data-row='${ilig}'][data-col='${jcol}']`
			target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.querySelectorAll(`td.props[data-row='${row}']  ${minj}, td.props[data-col='${col}'] ${minj}, td.props[data-car='${car}'] ${minj}`).forEach(tdd => {tdd.classList.remove('cachée')}) } 
		  const casecarolign = ({target}) => { // 2 et 2 bonus
			const { row, col, car } = target.parentElement.parentElement.parentElement.parentElement.dataset;
			target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.querySelectorAll(`td.props[data-row='${row}']  td, td.props[data-col='${col}'] td, td.props[data-car='${car}'] td`).forEach(tdd => {tdd.classList.remove('cachée')}) } 
		  const tousleségalit = ({target}) => {
			const { row:ilig, col:jcol } = target.dataset;
			target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.querySelectorAll(`td.vide[data-row='${ilig}'][data-col='${jcol}']`).forEach(tdd => {tdd.classList.remove('cachée')}) }
		  
		  const justeunecase = (tdmini) => { // 2 et 2
			justeremonte(tdmini);
			tdmini.forEach(td => { td.addEventListener('click', (e) => {		
				(document.getElementById('caroligne')?.checked) ? casecarolign(e) : e.target.parentElement.parentElement.querySelectorAll(`td.vide`).forEach(tdd => {tdd.classList.toggle('cachée')}) }); }) }
		  const tousleségalitios = (tdmini) => { // 2 et 1
			justeremonte(tdmini);
			tdmini.forEach(td => { td.addEventListener('click', (e) => {
				"*(somme ? raw"(document.getElementById('caroligne')?.checked) ?carolign(e) : " : raw" ")*raw"tousleségalit(e) })}) }
		  const carolignios = (tdmini) => { // 3 et 1
			justeremonte(tdmini);
			tdmini.forEach(td => { td.addEventListener('click', (e) => {
				(document.getElementById('caroligne')?.checked) ? carolign(e) : e.target.classList.toggle('cachée') }) }) } 
		  
		  const upme = (target) => { 
			if (document.getElementById('choixàmettreenhaut')?.checked) {
			const { row, col } = target.dataset;
			const lign = parseInt(row) + 1; const colo = parseInt(col) + 1;
			const vale = target.textContent;
			const cible = document.querySelector(`#sudokincipit > tbody > tr:nth-child(${lign}) >  td:nth-child(${colo}) > input[type=text]`);
			if (!isNaN(vale)) {
				cible.value = cible.value==vale ? 0 : vale ; 
				cible.value==0 ? target.classList.remove('ini') : target.classList.add('ini'); // ini gris ou bleu
				target.classList.remove('cachée');
				target.classList.add('gris'); 
			// document.getElementById('tesfoot')?.dispatchEvent(new Event('click'));
				cible.dispatchEvent(new Event('ctop')) } }};
		  const upmee = ({target}) => {upme(target)};
		  let tdbleus = _sudoku.querySelectorAll('td.ini');
		  tdbleus.forEach(tdbleu => { tdbleu.addEventListener('click', upmee) });
		  const touteffacer = (tdbleus) => { 
			tdbleus.forEach(tdbleu => { tdbleu.addEventListener('click', (e) => {
					if (!(document.getElementById('choixàmettreenhaut')?.checked)) {e.target.parentElement.parentElement.querySelectorAll(`td.vide`).forEach(tdd => {tdd.classList.add('cachée')}) }}) }) }	
		  let tdmini = _sudoku.querySelectorAll('td.mini'); 
		  //parCase = toutVoir # bidouille à changer ? toutVoir = true /// plus haut
		"*( toutVoir && parCase ? raw"justeremonte(tdmini); /* 3 et 2+3 */
			" : raw" /// let tdbleus = _sudoku.querySelectorAll('td.ini');
				touteffacer(tdbleus); 
				"*(parCase ? raw"justeunecase(tdmini); /* 2 et 2 */ 
					" : (toutVoir ? raw"tousleségalitios(tdmini); /* 3 et 1 + 2 et 3 */ " : raw"carolignios(tdmini); /* 2 et 1 */ ")) )* "
		  return _sudoku }
		
		return msga(createsudpropal($JPropal, $JSudokuini)); </script>")
	end
	htmlsp = sudpropal ## mini version
	htmatp = sudpropal ∘ matriceàlisteJS ## mini version 
	
#####################################################################################
# Fonction pricipale qui résout n'importe quel sudoku (même faux) ###################
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #
  function résoutSudokuMax(mS::Matrix{Int}, lesZéros::Set{Case}, dicoréz::Dicoréz, tours::Int = 0) 
	nbToursTotal = tours # ce nombre reprend le passage via résoutSudoku
	listedechoix = Choix[]
	listedancienneMat = Matrix{Int}[]
	listedesZéros = Set{Case}[] # leZéroàSuppr = Case(0,0,0,0:0,0:0) # ::Case
	nbChoixfait = 0
	minChoixdesZéros = 10
	allerAuChoixSuivant = false
	choixPrécédent = choixAfaire = Choix() # Choix(zéro, 1, minChoix, liste)
	listedancienImp = Dict{Tuple{Int,Int}, Set{Int}}[] # si dicOk 
	listedicoréz = Dicoréz[]
	mImp = Dict{Tuple{Int,Int}, Set{Int}}()
	çaNavancePas = true # Permet de voir si rien ne se remplit en un tour
	lesZérosàSuppr=Set{Case}()
	while !isempty(lesZéros) # && nbToursTotal < nbToursMax
		if !allerAuChoixSuivant
			nbToursTotal += 1
			çaNavancePas = true # reset à chaque tour
			minChoixdesZéros = 10
			dicompte = Dicompte()
			dicombo = Dicombo()
			for zéro in lesZéros
				listechiffre = chiPossible(mS,zéro,get!(mImp,(zéro.i,zéro.j),Set{Int}() ) ) 
				sac!(dicompte, zéro, listechiffre)
				if isempty(listechiffre) || pasAssezDePropal!(dicombo, zéro, mImp, dicoréz, listechiffre)
					allerAuChoixSuivant = true # donc mauvais choix 
					empty!(lesZérosàSuppr)
					break
				elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
					i,j,k = zéro.i,zéro.j,zéro.k
					pos=pop!(collect(listechiffre)) # le Set en liste
					ajoute(mS,zéro,i,j,k,pos,lesZérosàSuppr,dicoréz)
					nettoie(i,j,k,pos,dicompte)
					çaNavancePas = false # Car on a réussi à remplir
				elseif çaNavancePas && length(listechiffre) < minChoixdesZéros
					minChoixdesZéros = length(listechiffre)
					choixAfaire = Choix(zéro, 1, minChoixdesZéros, listechiffre) 
					# leZéroàSuppr = zéro # On garde les cellules avec … 
				end # … le moins de choix à faire, si ça n'avance pas
			end
		end # if allerAuChoixSuivant || çaNavancePas && (dImp == mImp) # en mieux ^^
		if allerAuChoixSuivant || uniclk!(dicompte,çaNavancePas,mS,lesZérosàSuppr,dicoréz,mImp)
			if allerAuChoixSuivant # Si le choix en cours n'est pas bon
				if isempty(listedechoix) # pas de bol hein
					#@info "1mp" nbToursTotal nbChoixfait mS lesZéros dicoréz mImp
					return impossible # faux car trop contraint → ex: 12345678+9
				elseif choixPrécédent.n < choixPrécédent.max # Aller au suivant
					(; c, n, max, rcl) = choixPrécédent
					choixPrécédent = Choix(c, n+1, max, rcl)
					listedechoix[nbChoixfait] = choixPrécédent
					mS = copy(listedancienneMat[nbChoixfait])
					mImp = deepcopy(listedancienImp[nbChoixfait])
					allerAuChoixSuivant = false
					mS[c.i,c.j] = pop!(rcl) 
					lesZéros = copy(listedesZéros[nbChoixfait])
					dicoréz = deepcopy(listedicoréz[nbChoixfait])
				elseif length(listedechoix) < 2 # pas 2 bol
					#@info "2bal" nbToursTotal nbChoixfait mS lesZéros dicoréz mImp
					return impossible
				else # Il faut revenir d'un cran dans la liste historique
					map(pop!,(listedechoix,listedancienneMat,listedancienImp, listedesZéros,listedicoréz))
					nbChoixfait -= 1
					choixPrécédent = listedechoix[nbChoixfait]
				end
			else # Nouveau choix à faire et à garder en mémoire
				caf = choixAfaire.c
				push!(listedechoix, choixAfaire) # ici pas besoin de copie
				push!(listedancienneMat , copy(mS)) # copie en dur
				push!(listedancienImp , deepcopy(mImp)) # copie en dur
				delete!(lesZéros, caf) # On retire ceux… idem set
				push!(listedesZéros , copy(lesZéros)) # copie en dur aussi
				nbChoixfait += 1
				isuppr, jsuppr, ksuppr = caf.i, caf.j, caf.k
				mS[isuppr, jsuppr] = pop!(choixAfaire.rcl)
				deletefun!(dicoréz, isuppr, jsuppr, ksuppr)
				push!(listedicoréz, deepcopy(dicoréz))
				choixPrécédent = choixAfaire
			end 
		else # !çaNavancePas && !allerAuChoixSuivant ## Tout va bien ici
			setdiff!(lesZéros, lesZérosàSuppr) # On retire ceux remplis 
			empty!(lesZérosàSuppr)
		end	
	end
	return toutestbienquifinitbien(mS, nbChoixfait, nbToursTotal)
  end
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  function résoutSudoku(JSudoku::Vector{Vector{Int}}, nbToursMax::Int = nbTmax) 
	nbToursTotal::Int = 0
	mS::Matrix{Int} = listeJSàmatrice(JSudoku) # Converti en vraie matrice
	# lesZéros = Set(shuffle!([Case(i,j,kelcarré(i,j),carr(i),carr(j)) for j in 1:9, i in 1:9 if mS[i,j]==0]))
	lesZéros = Set([Case(i,j,kelcarré(i,j),carr(i),carr(j)) for j in 1:9, i in 1:9 if mS[i,j]==0]) # le Set mélange déjà en partie
	listedechoix = Choix[] ## avant Tuple{Int,Int,Int,Int,Set{Int}}[]
	listedancienneMat = Matrix{Int}[]
	listedesZéros = Set{Case}[]
	nbChoixfait = 0
	minChoixdesZéros = 10
	allerAuChoixSuivant = false
	choixPrécédent = choixAfaire = Choix() # Choix(zéro, 1, minChoix, liste)
	çaNavancePas = true # Permet de voir si rien ne se remplit en un tour
	lesZérosàSuppr=Set{Case}()
	if vérifSudokuBon(mS)
		while !isempty(lesZéros) && nbToursTotal < nbToursMax
			if !allerAuChoixSuivant
				nbToursTotal += 1
				çaNavancePas = true # reset à chaque tour ? idem pour le reste ?
				minChoixdesZéros = 10
				for zéro in lesZéros
					listechiffre = simPossible(mS,zéro) 
					if isempty(listechiffre)
						allerAuChoixSuivant = true # donc mauvais choix
						empty!(lesZérosàSuppr)
						break
					elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
						mS[zéro.i,zéro.j]=pop!(collect(listechiffre)) ## Set en liste
						# mS[i,j]=pop!(listechiffre) ## ne fonctionne pas
						push!(lesZérosàSuppr, zéro)
						çaNavancePas = false # Car on a réussi à remplir
					elseif çaNavancePas && length(listechiffre) < minChoixdesZéros
						minChoixdesZéros = length(listechiffre)
						choixAfaire = Choix(zéro, 1, minChoixdesZéros, listechiffre)
						end # …le moins de choix à faire, si ça n'avance pas
				end
			end
			if allerAuChoixSuivant # Si le choix en cours n'est pas bon
				if isempty(listedechoix) # pas de bol hein
					#@info "1mp0" nbToursTotal nbChoixfait mS lesZéros JSudoku
					return impossible
				elseif choixPrécédent.n < choixPrécédent.max # Aller au suivant 
					(; c, n, max, rcl) = choixPrécédent
					choixPrécédent = Choix(c, n+1, max, rcl)
					listedechoix[nbChoixfait] = choixPrécédent
					mS = copy(listedancienneMat[nbChoixfait])
					allerAuChoixSuivant = false
					mS[c.i,c.j] = pop!(rcl)
					lesZéros = copy(listedesZéros[nbChoixfait])
				elseif length(listedechoix) < 2 # pas 2 bol
					#@info "2bal0" nbToursTotal nbChoixfait mS lesZéros JSudoku
					return impossible
				else # Il faut revenir d'un cran dans la liste historique 
					map(pop!,(listedechoix,listedancienneMat, listedesZéros))
					nbChoixfait -= 1
					choixPrécédent = listedechoix[nbChoixfait]
				end
			elseif çaNavancePas # Nouveau choix à faire et à garder en mémoire 
				caf = choixAfaire.c
				push!(listedechoix, choixAfaire) # ici pas besoin de copie
				push!(listedancienneMat , copy(mS)) # copie en dur
				delete!(lesZéros, caf) # On retire ceux… idem set ?
				push!(listedesZéros , copy(lesZéros)) # copie en dur aussi 
				nbChoixfait += 1
				mS[caf.i, caf.j] = pop!(choixAfaire.rcl)
				choixPrécédent = choixAfaire
			else # !çaNavancePas && !allerAuChoixSuivant ## Tout va bien ici
				setdiff!(lesZéros, lesZérosàSuppr) # On retire ceux remplis 
				empty!(lesZérosàSuppr)
			end	
		end
	else #@info "f0 dès le début" nbToursTotal nbChoixfait mS lesZéros JSudoku
		return àcorriger
	end
	if nbToursTotal >= nbToursMax
		!isempty(listedancienneMat) && 
			( mS = listedancienneMat[1] ; caf = listedechoix[1].c ; 
				mS[caf.i,caf.j] = 0 ; lesZéros = push!(listedesZéros[1],caf) )
		dicoréz = Dicoréz()
		for z in lesZéros
			pushfun!(dicoréz, z.i, z.j, z.k)
		end
		return résoutSudokuMax(mS, lesZéros, dicoréz, nbToursTotal) 
	else return toutestbienquifinitbien(mS, nbChoixfait, nbToursTotal)
	end
  end
  rjs = résoutSudoku ## mini version   ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  rmat = résoutSudoku ∘ matriceàlisteJS ## mini version   ## ## ## ## ## ## ## ## ##
# Fin de la fonction principale : résoutSudoku  ####################################
####################################################################################
  sudokuAléatoireFini()=listeJSàmatrice(résoutSudoku(jcvd())[1]) 
  # Génère un sudoku aléatoire fini et donc rempli (aucun vide)
  saf = maf = sudokuAléatoireFini ## mini version
  function sudokuAléatoire(x=19:62 ; fun=rand, matzéro=sudokuAléatoireFini())#rand1:81
  # Une fois le sudokuAléatoireFini, on le vide un peu d'un nombre x de cellules
	if !isa(x, Int) # Permet de choisir le nombre de zéro ou un intervale
		x=fun(x)
	end
	x = (0 <= x < 82) ? x : 81 # Pour ceux aux gros doigts, ou qui voit trop grand
	### liste = shuffle!([(i,j) for i in 1:9 for j in 1:9]) ## vrai shuffle
	liste = shuffle!(collect(Set([(i,j) for i in 1:9 for j in 1:9]))) # infox
	for (i,j) in liste[1:x] # nbApproxDeZéros
		matzéro[i,j] = 0
	end
	return matriceàlisteJS(matzéro)
  end

  function vieuxSudoku!(nouveau=sudokuAléatoire() ; défaut=false, r=true, remonte=true, mémoire=SudokuMémo, matzéro=sudokuAléatoireFini(), idLien="lien"*string(rand(Int)))
  # On peut retrouver un vieuxSudoku! pour le mettre au lieu du sudoku initial
  ## Exemple de sudoku :
  # vieuxSudoku!([[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,3,0,8,5],[0,0,1,0,2,0,0,0,0],[0,0,0,5,0,7,0,0,0],[0,0,4,0,0,0,1,0,0],[0,9,0,0,0,0,0,0,0],[5,0,0,0,0,0,0,7,3],[0,0,2,0,1,0,0,0,0],[0,0,0,0,4,0,0,0,9]])
	if défaut==true # Mégalomanie ## On revient à mon défaut ^^
		mémoire[2] = mémoire[3] = copy(mémoire[4])
	elseif isa(nouveau, Int) || isa(nouveau, UnitRange{Int})
		mémoire[2] = mémoire[3] = sudokuAléatoire(nouveau ; matzéro=matzéro)
	elseif nouveau==mémoire[1] 
		mémoire[2] = mémoire[3] = sudokuAléatoire()
	else mémoire[2] = mémoire[3] = copy(nouveau) # Astuce pour sauver le sudoku en cours
	end
	làhaut = (remonte && r ? "" : "// ")
	return Docs.HTML("<script>
	const ele = document.getElementsByName('ModifierInit');
	for(let ni=0;ni<ele?.length;ni++)
		ele[ni].checked = false; 

	function goSudokuIni() {
		document.getElementsByName('ModifierInit')[1].click();
	}
	document.getElementById('$idLien').addEventListener('click', goSudokuIni);
	goSudokuIni();
	$làhaut window.location.href = '#ModifierInit'; // remonte par défaut 
	</script><h6 style='margin-top: 0;'> Ci-dessous, le bouton ▶ restore le vieux sudoku en sudoku initial ! 🥳 <a id='$idLien' href='#ModifierInit'> retour en haut ↑ </a> </h6>")
  end
  vieux = vieux! = vs = vs! = vS! = vieuxSudoku! ## mini version
  vsd(;kwargs...) = vieuxSudoku!(;défaut=true,kwargs...) ## Pour revenir à l'original
  ini = défaut = defaut = vsd ## mini version
  vsr(;kw...) = vieuxSudoku!(0 ;kw...) ## Pour partir d'un sudoku rempli ou fini ^^
  vsf = vsaf = vsr ## mini version
  sudokuinitial!(;kw...) = vieuxSudoku!(SudokuMémo[3] ;kw...)
  vieuxSudoku!(nouv::Matrix{Int} ;kwargs...) = vieuxSudoku!(mjs(nouv') ;kwargs...)
end; nothing; # stylélàbasavecbonus! ## dans la cellule #Bonus au dessus ↑

##bid ╔═╡ be2c43a8-7001-7001-7001-bbbeebbbaa01
# using BenchmarkTools
##ouille ╔═╡ be2c43a8-7001-7001-7001-bbbeebbbaa02
# @benchmark résoutSudoku(bindJSudoku)

# Voilà ! fin de la plupart du code de ce programme Plutoku.jl

# ╔═╡ abde0004-0001-0004-0001-0004dabe0001
# ↗↗↗ MERCI d'appuyer sur "Run notebook code" ↗↗↗↗↗↗
# ↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↗↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↗↗↗↗↗↗↗
# Avant tout↗   puis ce code est masqué (cf. Bonus)

md"## Résoudre un Sudoku par Alexis $cool" 
#= ## v1.8.8 mercredi 06/12/2023 🧱🔠
 
Ce "Plutoku" est visible sur : 
https://github.com/4LD/plutoku

Si besoin, pour relancer ce Plutoku via Binder, plusieurs alias : 

https://cutt.ly/xsd

https://ovh.mybinder.org/v2/gh/fonsp/pluto-on-binder/HEAD?urlpath=pluto/open?url=https://raw.githubusercontent.com/4LD/plutoku/main/Plutoku.jl

https://cutt.ly/zsd

https://binder.plutojl.org/open?url=https:%252F%252Fraw.githubusercontent.com%252F4LD%252Fplutoku%252Fmain%252FPlutoku.jl 

Juste pour info, voici ci-dessous certains liens qui m'ont aidé (et un peu d'IA) : 
Pour la vue HTML et le style CSS, cela est inspiré du sudoku https://observablehq.com/@filipermlh/ia-sudoku-ple1
Pour le JavaScript, merci à (case suivante input) https://stackoverflow.com/a/15595732, (touches clavier) https://stackoverflow.com/a/44213036
https://github.com/fonsp/Pluto.jl et https://github.com/fonsp/pluto-on-binder
Et bien sûr le calepin d'exemple de Fons "Interactivity" 
Le code principal est stylélàbasavecbonus! ou plutôt caché juste après :)

## =#

# ╔═╡ abde0005-0002-0005-0002-0005dabe0002
begin 
	instantané # Bouton plus bas, la puce "ModifierInit" va sur Retour instantané ;)
	## push!(SudokuMémo,SudokuMémo[3]) ### histo si besoin ## instantané; SudokuMémo
	sudokuinitial!() # vieuxSudoku!(SudokuMémo[3]) Pour remplacer par celui modifié
	md""" $(@bind viderOupas puces(["Vider le sudoku initial","Retour instantané ;)"],2; idPuces="ModifierInit")) $(html" <a href='#Bonus' style='padding-left: 10px; border-left: 2px dotted var(--rule-color,#77777726);' >Bonus en bas ↓</a>") _: astuces + vieux!_"""
end

# ╔═╡ abde0006-0005-0006-0005-0006dabe0005
@bind bindJSudoku BondJamesBond(sudini(SudokuMémo, viderOupas), SudokuMémo[3])

# ╔═╡ abde0007-0004-0007-0004-0007dabe0004
begin 
	SudokuMémo[3] = bindJSudoku # Pour qu'il reste en mémoire → Retour instantané ;) 
	sst=sudokuSolution = résoutSudoku(bindJSudoku) #,nb)# @nombre # calcule 🚀
	ssv=sudokuSolutionVue = sudokuSolution[1] # Le sudoku résolu (voir plus loin)
	sudokuSolution[2] # La petite explication seule : "Statistiques : ce programme…"
end ## mesurable avec # using BenchmarkTools; ## @benchmark résoutSudoku(bindJSudoku)

# ╔═╡ abde0008-0006-0008-0006-0008dabe0006
viderOupas; md"""#### $vaetvient Sudoku initial ⤴ (modifiable) et sa solution : $(html"</span>") """

# ╔═╡ abde0009-0007-0009-0007-0009dabe0007
md"""$(@bind voirOuPas BondJamesBond(puces(["🤫 Cachée", "En touchant, entrevoir les chiffres…", "Pour toutes les cases, voir les chiffres…"], 1; idPuces="CacherRésultat"), "🤫 Cachée") ) 

$(html"<div style='border-bottom: 2px dotted var(--rule-color,#777);'></div>")

$(@bind PropalOuSoluce BondJamesBond(puces(["…par chiffre", "…par case 🔢", "…par total (minima = ✔)", "…de la solution 🚩"], 1; idPuces="PossiblesEtSolution", classe="pasla" ), "…par chiffre") ) 

$postpuce""" ## c'est →→→ # $(html"<div id='divers' class='pasla' style='margin-top: 8px; margin-left: 1%; user-select: none; font-style: italic; font-weight: bold; color: #777'><span id='pucaroligne'><input type='checkbox' id='caroligne' name='caroligne'><label for='caroligne' style='margin-left: 2px;'>Caroligne ⚔</label></span><span id='puchoixàmettreenhaut' style='margin-left: 5%'><input type='checkbox' id='choixàmettreenhaut' name='choixàmettreenhaut'><label for='choixàmettreenhaut' style='margin-left: 2px;'>Cocher ici, puis toucher le chiffre à mettre dans le Sudoku initial</label></span></div>")""")

# ╔═╡ abde0010-0008-0010-0008-0010dabe0008
if !@isdefined(voirOuPas) || !isa(voirOuPas, String) || voirOuPas == "🤫 Cachée"
	Markdown.parse( "###### 🤐 Cela est caché pour le moment comme demandé\n" * ( sudokuSolutionVue isa String ? "Malchance !" : "Bonne chance !" ) * 
" Si besoin, cocher `🤫 Cachée` pour revoir cette information : 

`En touchant, entrevoir les chiffres…` de chaque case…\\
_(petit truc : les chiffres en bleu réeffacent tout)_

   - `…par chiffre` et si possible : haut gauche = 1 au bas droite = 9 (centre de la case = 5)
   - `…par case 🔢` l'ensemble des chiffres possibles (de toute la case)
   - `…par total (minima = ✔)` fait la somme : minimum si ✔ au lieu du 9
   - seul `…de la solution 🚩` montre des chiffres du sudoku fini

On peut `Pour toutes les cases, voir les chiffres…` de la catégorie choisie

Enfin, il y a deux options :  
`Caroligne ⚔` pour les cases liées (carré, colonne, ligne) ; \\
ou `Cocher ici, puis toucher le chiffre à mettre dans le Sudoku initial`" )
elseif PropalOuSoluce == "…de la solution 🚩" # || PropalOuSoluce isa Missing
		sudfini(sudokuSolutionVue,bindJSudoku ; toutVoir= (voirOuPas=="Pour toutes les cases, voir les chiffres…") )
else sudpropal(bindJSudoku,sudokuSolutionVue ; toutVoir= (voirOuPas=="Pour toutes les cases, voir les chiffres…"), parCase= (PropalOuSoluce =="…par case 🔢"), somme= (PropalOuSoluce=="…par total (minima = ✔)"))
end

# ╔═╡ abde0011-0009-0011-0009-0011dabe0009
##bid ╔═╡ be2c43a8-7001-7001-7001-bbbeebbbaa01
# using BenchmarkTools
##ouille ╔═╡ be2c43a8-7001-7001-7001-bbbeebbbaa02
# @benchmark résoutSudoku(bindJSudoku)

stylélàbasavecbonus = #= style CSS pour le sudini…, le code principal est dans la cellule cachée tout en bas, juste après la cellule vide _`Enter cell code...`_" =# Docs.HTML(raw"""<style> /* Pour les boutons et 'code' */
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
	input[type="radio" i] {margin: 3px 0 3px 0;}
	.pasla, .maistesou{ /* visibility: hidden; */ filter: opacity(62%) blur(2px);}
	tr#lignenonvisible {border-top: hidden;}
	pluto-cell:not(.show_input) > pluto-runarea .runcell {display: none;}
	/* pluto-cell:not(.show_input) > pluto-runarea, */
	/* #abde0010-0008-0010-0008-0010dabe0008 > pluto-runarea, */
	#abde0007-0004-0007-0004-0007dabe0004 > pluto-runarea {
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
		//	  opacity: 0; /* to make it feel snappy: */
		//	  transition: opacity 0.05s ease-in-out;
		//  } 
	} </style>`;
const plutotemps = `<style id="beuuu">
	pluto-cell:not(.show_input) > pluto-runarea,
	pluto-cell > pluto-runarea {
		display: block !important;
		background-color: unset;
		opacity: 0.7;}
} </style>`; // const plutotemps = '' //// si vous laisser plutôt Pluto ////
function cooloupas() { 
	const BN = document.getElementById("BN");
	if (BN.textContent == "😉") { BN.textContent = "😎";} else { BN.textContent = "😉";};
};
document.getElementById("BN")?.removeEventListener("click", cooloupas);
document.getElementById("BN")?.addEventListener("click", cooloupas);

const stylécaché = html`<span id='stylé'>${""" * 
	(plutôtvoir ? "plutotemps" : "plutôtstylé") * raw"""}</span>`;
function styléoupas() { 
	const stylé = document.getElementById("stylé");
	const cachémoiplutôt = document.getElementById("cachémoiplutôt");
	if (cachémoiplutôt) { 
		stylé.innerHTML = ''; // stylé.innerHTML = plutotemps;
	} else {
		stylé.innerHTML = plutôtstylé;
	};
};
document.getElementById("plutot").addEventListener("click", styléoupas);
return stylécaché;
</script>"""); calepin = Docs.HTML(raw"<script>return html`<a href=${document.URL.search('.html')>1 ? document.URL.replace('html', 'jl') : document.URL.replace('edit', 'notebookfile')} target='_blank' download>${document.title.replace('🎈 ','').replace('— Pluto.jl','')}</a>`;</script>"); caleweb = Docs.HTML(raw"<script>return html`<a href=${document.URL.search('.html')>1 ? document.URL : document.URL.replace('edit', 'notebookexport')} target='_blank' style='font-weight: normal;' download>HTML</a>`;</script>"); plutoojl = Docs.HTML(raw"<script>if (document.URL.search('.html')>1) {
	return html`<em>Pluto.jl</em>`
	} else { return html`<a href='./' target='_blank' style='font-weight: normal;'><em>Pluto</em></a><em>.jl</em>`}</script>"); pourgarderletemps = Docs.HTML(raw"""<script>function générateurDeCodeClé() {
	const copyText = document.getElementById("pour-définir-le-sudoku-initial");
	const matrice = document.getElementById("sudokincipit").getAttribute('sudata').replaceAll('],[','; ').replaceAll(',',' ').replace('[[','[').replace(']]',']');
	copyText.value = 'vieuxSudoku!(' + matrice + ')';
	copyText.select();
	navigator.clipboard.writeText(copyText.value); // document.execCommand("copy");
}
document.getElementById("clégén").addEventListener("click", générateurDeCodeClé);
	
const editCSS = document.createElement('style');
editCSS.id = "touslestemps";
var togglé = "0";

let touslestemps = document.getElementsByClassName("runtime");
// touslestemps.forEach( e => { // ne fonctionne pas :'(
for(let j=0; j<(Object.keys(touslestemps).length); j++){
	touslestemps[j].addEventListener("click", (e) => {
		// alert(e.target.classList.toggle("opaqueoupas"));
		const stylét = document.getElementById("touslestemps");
		togglé = (togglé==="0") ? "0.7" : "0" ;
		stylét.textContent = "pluto-cell > pluto-runarea { opacity: "+ togglé + "; }";
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
   4. Pour rigoler, la fonction **lettres!**(), **lettre**() ou **l**() met 🙂 dans le sudoku. Un texte entre **""**, comme **l**(**"md"**) fait M et D, à noter dans _`Enter cell code...`_ ← **l**(**:md**) fonctionne aussi
   5. Pour information, la fonction **vieuxSudoku!**(), **vieux!**() ou **vs**(), sans paramètre permet de générer un sudoku aléatoire. En mettant un nombre, par exemple **vieux!**(**62**) : ce sera le total de cases vides du sudoku aléatoire construit. Enfin, en mettant un intervalle, sous la forme **début : fin**, par exemple **vieux**(**0:81**) : un nombre aléatoire dans cet intervalle sera utilisé. Pour les sudokus aléatoires, le fait de recliquer sur le bouton ▷ en génère un nouveau 
   6. Le code de ce programme en [_Julia_](https://fr.wikipedia.org/wiki/Julia_(langage_de_programmation)) est observable en cliquant d'abord sur $(html"<input type=button id='plutot' value='Ceci 📝🤓'>") pour basculer sur l'interface de $plutoojl, puis en cliquant sur l'œil 👁 à côté de chaque cellule. Il est aussi possible de télécharger ce calepin $calepin ou en $caleweb
$(html"</details></details>")
$pourvoirplutôt 
$stylélàbasavecbonus
$pourgarderletemps"""; begin
############### fonction bonus pour dessiner dans le sudoku #####################
  l0()=Set{Tuple{Int,Int}}() # set init oire avec l'alpha art, sans Milou
  rangé(début::Int, fin::Int) = (début<fin ? (début:fin) : fin:début) # :² :)
  rétr(oi::Int, fi::Int)=oi > fi ? max(oi-1,fi) : min(oi+1,fi) # rétrécit / rétracte
  function lsegment!(oi::Int, oj::Int, fi::Int, fj::Int; ld::Set{Tuple{Int,Int}}=l0())
	if oi == fi for j in rangé(oj,fj)
		push!(ld, (oi, j))
		end
	elseif oj == fj for i in rangé(oi,fi)
		push!(ld, (i, oj))
		end
	else 
		push!(ld, (oi, oj))
		push!(ld, (fi, fj))
		(abs(oj-fj)>1 || abs(oi-fi)>1) && lsegment!(rétr(oi,fi),rétr(oj,fj), rétr(fi,oi),rétr(fj,oj) ;ld)
	end
	return ld # avec bords
  end
  lsegment!(args...; ld::Set{Tuple{Int,Int}}=l0()) = (lsegment!(args[1:4]...;ld); lsegment!(args[5:end]... ;ld))
  lsegment!(liste::Tuple; ld::Set{Tuple{Int,Int}}=l0()) = lsegment!(liste...;ld)
  lsegment!(l::Tuple,s...;ld::Set{Tuple{Int,Int}}=l0())=lsegment!(s...;ld=lsegment!(l;ld))
  lsegment!(i1,i2, jj::UnitRange,s...;ld::Set{Tuple{Int,Int}}=l0())=lsegment!(((i1,j,i2,j) for j∈jj)...)
  lsegment!(ii::UnitRange, j1,j2,s...;ld::Set{Tuple{Int,Int}}=l0())=lsegment!(((i,j1,i,j2) for i∈ii)...)
  function lrond!(oi::Int, oj::Int, fi::Int, fj::Int; ld::Set{Tuple{Int,Int}}=l0())
	roi,roj, rfi,rfj = rétr(oi,fi),rétr(oj,fj), rétr(fi,oi),rétr(fj,oj)
	lsegment!(oi,roj, oi,rfj ;ld) ## = …;ld=ld)
	lsegment!(roi,fj, rfi,fj ;ld)
	lsegment!(fi,rfj, fi,roj ;ld)
	lsegment!(rfi,oj, roi,oj ;ld) # sans coins
  end
  lrond!(args...; ld::Set{Tuple{Int,Int}}=l0()) = (lrond!(args[1:4]...;ld);lrond!(args[5:end]... ;ld))
  lrond!(liste::Tuple; ld::Set{Tuple{Int,Int}}=l0()) = lrond!(liste...;ld)
  lrond!(l::Tuple,s...; ld::Set{Tuple{Int,Int}}=l0()) = lrond!(s...;ld=lrond!(l;ld))
  function lcarré!(oi::Int, oj::Int, fi::Int, fj::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(oi,oj, fi,fj ;ld) 
	return union!(ld, Set([(oi,oj),(oi,fj),(fi,fj),(fi,oj)])) # avec coins
  end
  lcarré!(args...; ld::Set{Tuple{Int,Int}}=l0()) = (lcarré!(args[1:4]...;ld);lcarré!(args[5:end]... ;ld))
  lcarré!(liste::Tuple; ld::Set{Tuple{Int,Int}}=l0()) = lcarré!(liste...;ld)
  lcarré!(l::Tuple,s...; ld::Set{Tuple{Int,Int}}=l0()) =lcarré!(s...;ld=lcarré!(l;ld))
  lpoint!(oi::Int, oj::Int; ld::Set{Tuple{Int,Int}}=l0()) = push!(ld, (oi,oj))
  lpoint!(args...; ld::Set{Tuple{Int,Int}}=l0()) = (lpoint!(args[1],args[2];ld); lpoint!(args[3:end]... ;ld))
  lpoint!(liste::Tuple; ld::Set{Tuple{Int,Int}}=l0()) = lpoint!(liste...;ld)
  lpoint!(l::Tuple,s...; ld::Set{Tuple{Int,Int}}=l0()) =lpoint!(s...;ld=lpoint!(l;ld))
  lpoint!(ii::UnitRange, jj::UnitRange,s...;ld::Set{Tuple{Int,Int}}=l0())=(for i∈ii, j∈jj lpoint!(i,j ;ld) end; ld)
  lpoint!(ii::UnitRange, oj,s...;ld::Set{Tuple{Int,Int}}=l0())=(for i∈ii lpoint!(i,oj ;ld) end; ld)
  lpoint!(oi, jj::UnitRange,s...;ld::Set{Tuple{Int,Int}}=l0())=(for j∈jj lpoint!(oi,j ;ld) end; ld)
  lpoint!(oi::Int ;ld::Set{Tuple{Int,Int}}=l0())=push!(ld, (oi,oi))
  lpoint!(ij::UnitRange ;ld::Set{Tuple{Int,Int}}=l0())=lpoint!(ij,ij ;ld)

  darkl!(fun, args...; ld::Set{Tuple{Int,Int}}=l0())=setdiff!(ld,fun(args...;ld=l0()))

  function lsourire!(; ld::Set{Tuple{Int,Int}}=l0())
	lpoint!(6,3,   6,7 ;ld)
	lsegment!(7,4, 7,6 ;ld)
	lcarré!(3,3, 4,4,   3,6, 4,7 ;ld)
	lrond!(1,1, 9,9 ;ld)
  end
  function lA!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lcarré!(3+i,1+j, 5+i,3+t+j ;ld)
	t>=0 && darkl!(lsegment!, 5+i,2+j,   5+i,2+t+j ;ld)
	lrond!(1+i,1+j, 3+i,3+t+j ;ld)
  end
  function lB!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(1+i,1+j, 3+i,3+t+j,   3+i,1+j, 5+i,3+t+j ;ld)
	lpoint!(1+i,1+j,   3+i,1+j,   5+i,1+j ;ld)
  end; lẞ! = lB!;
  function lC!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(1+i,1+j, 5+i,3+t+j ;ld) # 	lcarré!(1+i,1+j, 5+i,4+j ;ld) ## C carré
	darkl!(lpoint!, 3+i,3+t+j ;ld) # 	darkl!(lsegment!, 2+i,4+j, 4+i,4+j ;ld)
  end
  function lD!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(1+i,1+j, 5+i,3+t+j ;ld)
	lpoint!(1+i,1+j,   5+i,1+j ;ld)
  end
  function lF!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 1+i,3+t+j,   2+i,1+j, 5+i,1+j,   3+i,2+j, 3+i,2+t+j ;ld)
  end
  function lE!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lF!(j,t,i ;ld)
	lsegment!(5+i,2+j, 5+i,3+t+j ;ld)
  end
  function lG!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lcarré!(1+i,1+j, 5+i,3+t+j ;ld)
	darkl!(lpoint!, 2+i,3+t+j ;ld)
	lpoint!(3+i,2+t+j ;ld)
  end
  function lH!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,1+j,   4+i,3+t+j, 5+i,3+t+j,   3+i,1+j, 3+i,2+t+j ;ld)
  end 								# 1+i… →→→ H au lieu de h
  function lI!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lpoint!(1+i,1+1+t+j ;ld)
	lsegment!(3+i,1+1+t+j, 5+i,1+1+t+j ;ld)
  end
  function lJ!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lcarré!(1+i,1+j, 5+i,2+t+j ;ld)
	darkl!(lsegment!, 1+i,1+j, 3+i,1+j ;ld)
	lpoint!(1+i,3+t+j ;ld) #	darkl!(lpoint!, 1+i,2+j, 2+i,3+j ;ld) ## j et non J
  end
  function lK!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,1+j,   3+i,2+j, 1+i,3+t+j,   3+i,2+j, 5+i,3+t+j ;ld)
  end
  function lL!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,1+j,   5+i,2+j, 5+i,2+1+t+j ;ld)
  end
  function lM!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,1+j,   1+i,3+t+j, 5+i,3+t+j,   2+i,j, 3+i,1+max(t,1)+j,   3+i,1+max(t,1)+j, 2+i,2+t+j ;ld)
	t==1 && lpoint!(2+i,2+j, 3+i,3+j ;ld)
	darkl!(lpoint!, 2+i,j ;ld)
  end
  function lN!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,3+t+j,   1+i,1+j, 5+i,1+j,   1+i,3+t+j, 5+i,3+t+j ;ld)
  end
  function lO!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(1+i,1+j, 5+i,3+t+j ;ld)
  end
  function lP!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,1+j ;ld)
	lrond!(1+i,1+j, 3+i,3+t+j ;ld)
  end
  function lQ!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	t=1; lrond!(1+i,1+j, 5+i,3+t+j ;ld)
	darkl!(lpoint!, 5+i,2+t+j,   4+i,3+t+j ;ld)
	lsegment!(3+i,2+j, 5+i,3+t+j ;ld)
  end
  function lR!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lP!(j,t,i ;ld)
	lsegment!(3+i,1+t+j, 5+i,3+t+j ;ld)
  end
  function lS!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(1+i,1+j, 3+i,2+1+t+j,   3+i,1+j, 5+i,2+1+t+j ;ld)
	darkl!(lpoint!, 4+i,1+j,   2+i,2+1+t+j ;ld)
	lpoint!(5+i,1+j, 1+i,2+1+t+j ;ld)
  end
  function lT!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 1+i,3+t+j,   1+i,j+(4+t)÷2, 5+i,j+(4+t)÷2)
  end
  function lU!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lrond!(1+i,1+j, 5+i,3+t+j ;ld)
	darkl!(lsegment!, 1+i,1+j, 1+i,3+t+j ;ld)
	t==0 && lpoint!(5+i,1+j, 5+i,3+t+j ;ld)
	lpoint!(1+i,1+j, 1+i,3+t+j ;ld)
  end
  function lV!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	u = t==1 ? 1 : 0 ; v = t==3 ? 1 : 0
	t==0 && lpoint!(5+i,2+t+j,   4+i,1+j,   4+i,3+t+j ;ld)
	t>0 && lsegment!(3+u+i,1+j, 5+i,j+(4+t)÷2,   5+i,j+(4+t)÷2, 3-v+i,3+t+j ;ld)
	lsegment!(1+i,1+j, 3+i,1+j,   1+i,3+t+j, 3-v+i,3+t+j ;ld)
  end
  function lW!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 5+i,1+j,   1+i,3+t+j, 5+i,3+t+j,   4+i,j, 3+i,1+max(t,1)+j,   3+i,1+max(t,1)+j, 4+i,2+t+j ;ld)
	t==1 && lpoint!(4+i,2+j, 3+i,3+j ;ld)
	darkl!(lpoint!, 4+i,j ;ld)
  end
  function lX!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 2+i,1+j,   4+i,1+j, 5+i,1+j,   3+i,2+j, 3+i,2+t+j,   1+i,3+t+j, 2+i,3+t+j,   4+i,3+t+j, 5+i,3+t+j ;ld)
  end
  function lY!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(1+i,1+j, 2+i,1+j,   3+i,2+j, 3+i,2+t+j,   1+i,3+t+j, 4+i,3+t+j,   5+i,1+j, 5+i,2+t+j ;ld)
  end
  function lZ!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	u = t<2 ? 1 : 0 # Je trouve que c'est plus joli si t est < 1 comme cela
	lsegment!(1+i,1+j, 1+i,3+t+j,   5+i,1+j, 5+i,3+t+j,   1+u+i,3+t+j, 5-u+i,1+j ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ  https://fr.wikipedia.org/wiki/Diacritiques_utilisés_en_français
  function laigu!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(i,j+(3+t)÷2, -1+i,j+1+(3+t)÷2 ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ 
  function lgrave!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(-1+i,j+(3+t)÷2, i,j+1+(3+t)÷2 ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ 
  function lcirconfl!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(i,1+j, -1+i,2+j,   -1+i,2+j, -1+i,2+t+j,   -1+i,2+t+j, i,3+t+j ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ 
  function ltréma!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lpoint!(-1+i,j+(3+t)÷2, -1+i,j+2+(3+t)÷2 ;ld) #lpoint!(-1+i,1+j, -1+i,3+t+j ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ 
  function lcédille!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(6+i,j+(3+t)÷2, 7+i,j+1+(3+t)÷2 ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ 
  function ltilde!(j=0::Int,t=1,i=2::Int; ld::Set{Tuple{Int,Int}}=l0())
	lsegment!(i,1+j, -1+i,3+t+j ;ld)
  end # àâäçéèêëîïôöùûüÿæœñß ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸÆŒÑẞ 
  
  lÀ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lA!(j,t,i;ld); lgrave!(j,t,i;ld))
  lÂ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lA!(j,t,i;ld); lcirconfl!(j,t,i;ld))
  lÄ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lA!(j,t,i;ld); ltréma!(j,t,i;ld))
  lÇ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lC!(j,t,i;ld); lcédille!(j,t,i;ld))
  lÉ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lE!(j,t,i;ld); laigu!(j,t,i;ld))
  lÈ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lE!(j,t,i;ld); lgrave!(j,t,i;ld))
  lÊ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lE!(j,t,i;ld); lcirconfl!(j,t,i;ld))
  lË!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lE!(j,t,i;ld); ltréma!(j,t,i;ld))
  li!(j,t,i; ld::Set{Tuple{Int,Int}}=l0())=lsegment!(1+i,1+j+(3+t)÷2,5+i,1+j+(3+t)÷2;ld)
  lÎ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(li!(j,t,i;ld); lcirconfl!(j,t,i;ld))
  lÏ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(li!(j,t,i;ld); ltréma!(j,t,i;ld))
  lÔ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lO!(j,t,i;ld); lcirconfl!(j,t,i;ld))
  lÖ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lO!(j,t,i;ld); ltréma!(j,t,i;ld))
  lÙ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lU!(j,t,i;ld); lgrave!(j,t,i;ld))
  lÛ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lU!(j,t,i;ld); lcirconfl!(j,t,i;ld))
  lŸ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lY!(j,t,i;ld); ltréma!(j,t,i;ld))
  lÆ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lA!(j,t-1,i;ld); lE!(j+1+t,t-2,i;ld))
  lŒ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lO!(j,t-1,i;ld); lE!(j+1+t,t-2,i;ld))
  lÑ!(j=0,t=1,i=2; ld::Set{Tuple{Int,Int}}=l0())=(lN!(j,t,i;ld); ltilde!(j,t,i;ld))
  ## … # end; lẞ! = lB!;
  
  function videunpeu!(ljs::Vector{Vector{Int}}; ld::Set{Tuple{Int,Int}}=l0())
	for (i,j) in ld if i∈1:9 && j∈1:9 ljs[i][j] = 0
	end end
	return ljs
  end
  vu! = videunpeu! ## mini version (ou alias plus court si besoin)
  function remplit!(ljs::Vector{Vector{Int}}; ld::Set{Tuple{Int,Int}}=l0())
	lini=l0()
	for j in 1:9, i in 1:9 if ljs[i][j]≢0
		push!(lini, (i, j))
	end end 
	ljs = résoutSudoku(ljs)[1]
	ld2 = setdiff!(Set([(li,co) for li in 1:9, co in 1:9]), lini, ld)
	for (i,j) in ld2 if i∈1:9 && j∈1:9 ljs[i][j] = 0
	end end
	return ljs
  end
  # rp = remplit ## mini version (ou alias plus court si besoin)
  # function videpresquetout!(ljs::Vector{Vector{Int}}; ld::Set{Tuple{Int,Int}}=l0())
	# for (i,j) in setdiff!(Set([(li,co) for li in 1:9, co in 1:9]), ld)
		# ljs[i][j] = 0
	# end
	# return ljs
  # end ## vp! = videpresquetout! ## mini version (ou alias plus court si besoin)
  fonctexte(texte) = eval(Symbol("l",uppercase(string(texte)),"!")) # failleSécuOk :)
  function llettres!(texte="",j...=0) # pré-fonction pour faire une liste de lettres
	lt = collect(string(texte)) # même des Symbol avec accents :tôp dans le sudoku
	long = length(lt)
	if long == 1
		fonctexte(lt[1])(j...)
	elseif long == 2
		union!(fonctexte(lt[1])(),fonctexte(lt[2])(5))
	elseif long == 3 ## pas top dans ce cas (dépend des lettres)
		union!(fonctexte(lt[1])(0,0),fonctexte(lt[2])(2,2),fonctexte(lt[3])(6,0))
	else lsourire!() # au pire on sourit 🙂 :)
	end
  end
  llettres!(liste::Tuple)=llettres!(liste...) # Tuple d'args
  llettres!(liste::Tuple,suite...)=union!(llettres!(liste), llettres!(suite...))
  rembo!(ljs) = (SudokuMémo[3]=SudokuMémo[2]=deepcopy(ljs))
  mémo!(i::Int)=rembo!(SudokuMémo[i]) # inception de la mémoire
  mémo!(x...)=rembo!(SudokuMémo[1]) # reset de la mémoire
  mémo!(tre::Vector{Vector{Int}})=rembo!(tre) # si on donne ljs
  mémo!(tre::Matrix{Int})=rembo!(mjs(tre)) # si dans la matrice
  dessine!(lsegment! ; ini=3)=vieuxSudoku!(remplit!(mémo!(ini) ;ld=lsegment!))
  dessine!(lrond!, lpoint!... ; ini=3)=dessine!(union(lrond!,lpoint!...);ini)
  # gomme!(p::Tuple,i::Tuple ; ini=3)=dessine!(setdiff!(union!(p...),i...);ini)
  # gomme!(p::Tuple,is... ; ini=3)=dessine!(setdiff!(union!(p...),is...);ini)
  # gomme!(p, lsourire!...;ini=3)=dessine!(setdiff!(union!(lsourire!...),lpoint!);ini)
  gomme!(lsegment! ; ini=3)=vieuxSudoku!(videunpeu!(mémo!(ini) ;ld=lsegment!))
  gomme!(lrond!, lpoint!... ; ini=3)=gomme!(union(lrond!,lpoint!...);ini)
  lettres!(x... ; ini = 1)=dessine!(llettres!(x...) ; ini) ## SudokuMémo[1] = vide
  ligne!(i::Int ; ini=3)=dessine!(lsegment!(i,1,i,9) ;ini)
  ligne!(ii::UnitRange ; ini=3)=dessine!(lsegment!(ii, 1,9) ;ini)
  ligne!(x... ; ini=3)=dessine!(lsegment!(x...) ;ini)
  colonne!(j::Int ; ini=3)=dessine!(lsegment!(1,j,9,j) ;ini)
  colonne!(jj::UnitRange ; ini=3)=dessine!(lsegment!(1,9,jj) ;ini)
  colonne!(x... ; ini=3)=dessine!(lsegment!(x...) ;ini)
  case!(x... ; ini=3)=dessine!(lpoint!(x) ;ini)
  l = lettre = lettre! = lettres = lettres! ## mini version 
  d = dessine = dessine! ## mini version 
  g = gomme = gomme! ## mini version 
  s = segment = lsegment = lsegment! ## …
  r = rond = lrond = lrond!
  c = carré = lcarré = lcarré! ### /!\ avant carré() existait
  p = point = lpoint!
  🙂 = lol = smiley = sourire = lsourire = lsourire!
  li = ligne = ligne!
  co = colonne = colonne!
  ca = case!
  # dessine = dessine! ## mini version 
  # gomme = gomme! ## mini version 
  # segment = lsegment = lsegment! ## …
  # rond = lrond = lrond!
  # carré = lcarré = lcarré! ### /!\ avant carré() existait
  # point = lpoint!
  # sourire = lsourire = lsourire!
  # ligne = ligne!
  # colonne = colonne!
  ### case!
  
  #=  ### D'autres fonctions si besoin pour tester et repérer des erreurs :
  function sudokuAlt(nbChiffresMax=rand(26:81), moinsOK=true, nbessai=1) 
  # Sorte de sudokuAléatoire mais un peu plus foireux, en effet, il n'est pas forcément réalisable. C'était surtout pour faire des tests.
	nbChiffres = 1
	mS::Matrix{Int} = zeros(Int, 9,9) # Matrice de zéro
	lesZéros = shuffle!([Case(i,j) for j in 1:9, i in 1:9])# Fast & Furious
	for zéro in lesZéros
		if nbChiffres > nbChiffresMax
			return mS
		else 
		listechiffre = simPossible(mS, zéro)
			if isempty(listechiffre) ### Pas bon signe ^^
				if moinsOK || nbessai > 26
					return mS
				else 
					return sudokuAlt(nbChiffresMax, false, nbessai+1)
				end
			else # length(listechiffre) == 1 # L'idéal, une seule possibilité
				# mS[i,j]=collect(listechiffre)[1]
				mS[zéro.i,zéro.j]=pop!(listechiffre)
				nbChiffres += 1
			end
		end
	end
  end
  salt = sudokuAlt ## mini version
  rsalt = résoutSudoku ∘ matriceàlisteJS ∘ sudokuAlt ## mini version
  function blindtest(nbtest=100 ; tmax=81, nbzéro = (rand, 7:77), sudf=sudokuAléatoireFini)
  # Permet de tester la rapidité et certains bugs de ma fonction principale résoutSudoku. C'est donc une fonction qui est technique et qui sert surtout quand il y a des évolutions de cette fonction.
	nbzérof() = isa(nbzéro,Tuple) && ( nbzéro=nbzéro[1](nbzéro[2]) )
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
		soluce = résoutSudoku(sudaléa, tmax)
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
  bt = testme = blindtest ## mini version  =#
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
	# export *, ^ ### join à intégrer aussi ?
	ccat(c1, c2, ss=:no) = isfusionable(c1, c2, ss) ? fusion(c1, c2, ss) : vcat(c1,c2)
	*(m1::Markdown.MD, m2::Markdown.MD) = Markdown.MD(ccat(m1.content, m2.content))
	*(m::Markdown.MD, s::Union{AbstractChar, AbstractString, Docs.HTML}) = 
		Markdown.MD(ccat(m.content, parsebis(s).content, :right))
	*(s::Union{AbstractChar, AbstractString, Docs.HTML}, m::Markdown.MD) = 
		Markdown.MD(ccat(parsebis(s).content, m.content, :left))
	*(m::Markdown.MD) = m # avoids wrapping m in a useless subpattern (as Regex.jl)
	^(m::Markdown.MD, i::Int) = *(Markdown.MD(),fill(m,i)...)
 	
	isfusionable(c1, c2, stringside::Symbol) = 
		!isempty(c1) && !isempty(c2) && (issimilar(c1[end], c2[1]) || 
			(stringside == :right ? c2[1] isa Markdown.Paragraph : 
				(stringside == :left ? c1[end] isa Markdown.Paragraph : false)) )
	fusion(c1, c2, stringside::Symbol) = 
		vcat(c1[1:end-1], premerge(c1[end], c2[1], stringside), c2[2:end])
	
	issimilar(::Any, ::Any) = false # by default it !issimilar
	issimilar(::Markdown.Paragraph, ::Markdown.Paragraph) = true # md"is " * md" good ?"
	issimilar(h1::Markdown.Header{l1}, h2::Markdown.Header{l2}) where {l1,l2} = (l1==l2)
	issimilar(c1::Markdown.Code, c2::Markdown.Code) = (c1.language == c2.language)
	issimilar(f1::Markdown.Footnote, f2::Markdown.Footnote) = (f1.id == f2.id)
	issimilar(::Markdown.BlockQuote, ::Markdown.BlockQuote) = true 
	issimilar(a1::Markdown.Admonition, a2::Markdown.Admonition) = 
		(a1.category == a2.category) && (a1.title == a2.title)
	issimilar(l1::Markdown.List,l2::Markdown.List) = 
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
end;  bonusetastuces

# ╔═╡ Cell order:
# ╟─abde0004-0001-0004-0001-0004dabe0001
# ╟─abde0005-0002-0005-0002-0005dabe0002
# ╟─abde0001-0003-0001-0003-0001dabe0003
# ╟─abde0007-0004-0007-0004-0007dabe0004
# ╟─abde0006-0005-0006-0005-0006dabe0005
# ╟─abde0008-0006-0008-0006-0008dabe0006
# ╟─abde0009-0007-0009-0007-0009dabe0007
# ╟─abde0010-0008-0010-0008-0010dabe0008
# ╟─abde0011-0009-0011-0009-0011dabe0009
# ╠═abde0002-0010-0002-0010-0002dabe0010
# ╟─abde0003-0011-0003-0011-0003dabe0011
