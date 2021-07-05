### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 43ec2840-239d-11eb-075a-071ac0d6f4d4
begin 
	# @bind bindJSudoku SudokuInitial # et son javascript est inclus au plus haut
	# stylélàbasavecbonus! ## voir juste dans la cellule #Bonus au dessus ↑
	
	const set19 = Set(1:9) # Pour ne pas le recalculer à chaque fois
	const cool = html"<span id='BN' style='user-select: none;'>😎</span>";
	const coool = html"<span id='BoN' style='user-select: none;'>😎</span>"
	jsvd() = fill(fill(0,9),9) # JSvide ou JCVD ^^ pseudo const
	using Random: shuffle! # Astuce pour être encore plus rapide = Fast & Furious
	## shuffle!(x) = x ## Si besoin, mais... Everyday I shuffling ! (dixit LMFAO)

	SudokuMémo=[[[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]],
	[[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,1,2,3,4,5,0,0,0],[0,2,0,0,3,0,6,0,0],[0,3,4,5,6,0,0,7,0],[0,6,0,0,7,0,8,0,0],[0,7,0,0,8,9,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]],
	[[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,1,2,3,4,5,0,0,0],[0,2,0,0,3,0,6,0,0],[0,3,4,5,6,0,0,7,0],[0,6,0,0,7,0,8,0,0],[0,7,0,0,8,9,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]],
	[[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,1,2,3,4,5,0,0,0],[0,2,0,0,3,0,6,0,0],[0,3,4,5,6,0,0,7,0],[0,6,0,0,7,0,8,0,0],[0,7,0,0,8,9,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]]] # En triple pour garder mes initial(e)s ^^
	
	listeJSàmatrice(JSudoku::Vector{Vector{Int}}) = hcat(JSudoku...) #' en pinaillant
	jsm = listeJSàmatrice ## mini version
	matriceàlisteJS(mat,d=9) = [mat[:,i] for i in 1:d] #I will be back! ## mat3 aussi
	mjs = matriceàlisteJS ## mini version
	# matriceàlisteJS(listeJSàmatrice(JSudoku)) == JSudoku ## Logique, non ?
	nbcm(mat) = count(>(0), mat ) # Nombre de chiffres > 0 dans une matrice
	nbcj(ljs) = count(>(0), listeJSàmatrice(ljs) ) # idem pour une liste JS

	kelcarré(i::Int,j::Int) = 1+ 3*div(i-1,3) + div(j-1,3) # n° du carré du sudoku
	carré(i::Int,j::Int)= 1+div(i-1,3)*3:3+div(i-1,3)*3, 1+div(j-1,3)*3:3+div(j-1,3)*3 # permet de fabriquer les filtres pour ne regarder qu'un seul carré
	vues(mat::Array{Int,2},i::Int,j::Int)= (view(mat,i,:), view(mat,:,j), view(mat, carré(i,j)...)) # liste des chiffres possible par lignes, colonnes et carrés
	listecarré(mat::Array{Int,2})= [view(mat,carré(i,j)...) for i in 1:3:9 for j in 1:3:9] # La liste de tous les carrés du sudoku
	chiffrePossible(mat::Array{Int,2},i::Int,j::Int)= setdiff(set19,vues(mat,i,j)...) # Pour une case en i,j

	function vérifSudokuBon(mat::Array{Int,2})
		lescarrés = listecarré(mat)
		for x in 1:9 # Pour tous les chiffres de 1 à 9...
			for i in 1:9 # ...est-il en doublon dans une ligne ?
				if count(==(x), mat[i,:])>1
					return false
				end
			end
			for j in 1:9 # ...est-il en doublon dans une colonne ?
				if count(==(x), mat[:,j])>1
					return false
				end
			end
			for c in lescarrés # ...est-il en doublon dans un carré ?
				if count(==(x), c)>1
					return false
				end
			end
		end
		return true # Le sudoku semble conforme (mais il peut être impossible)
	end 
	
	# function nbZérosEnLien(listeZéros, clé) 
	#	# une clé pour tous les touchées (bonus :) 
	#	## C'était aussi dans une idée d'optimisation... mais ça faisait perdre du temps ^^
	# 	(itest,jtest) = listeZéros[clé]
	# 	nbZérosVus = 0
	# 	for (i,j) in listeZéros
	# 		if i == itest || j == jtest || kelcarré(i,j)==kelcarré(itest,jtest)
	# 			nbZérosVus +=1
	# 		end
	# 	end
	# 	return nbZérosVus - 1 # pour ne pas s'autocompter
	# end
	function pasAssezDePropal!(listepossibles::Set{Int},dictCheckLi::Dict{Set{Int}, Int},dictCheckCj::Dict{Set{Int}, Int},dictCheckCarré::Dict{Set{Int}, Int})
	# Ici l'idée est de voir s'il y a plus chiffres à mettre que de cases : en regardant tout ! entre deux cases, trois cases... sur la ligne, colonne, carré ^^
	# Bref, s'il n'y a pas assez de propositions pour les chiffres à caser c'est vrai
		dili = copy(dictCheckLi)
		dico = copy(dictCheckCj)
		dica = copy(dictCheckCarré)

		for (k,v) in dili # Pour les lignes
			kk = union(k,listepossibles)
			if length(kk) > v
				dictCheckLi[kk] = max(get(dictCheckLi, kk, 0) ,v+1) 
				# dictCheckLi[kk] = v + 1 # ex: [1,2]=>1 et [2,3]=>1 = [1,2,3]=>2
			else 
				return true
			end
		end	
		for (k,v) in dico # Pour les colonnes
			kk = union(k,listepossibles)
			if length(kk) > v
				dictCheckCj[kk]= max(get(dictCheckCj, kk, 0) ,v+1) 
			else 
				return true
			end
		end	
		for (k,v) in dica # Pour les carrés
			kk = union(k,listepossibles)
			if length(kk) > v
				dictCheckCarré[kk] = max(get(dictCheckCarré, kk, 0) ,v+1) 
			else 
				return true
			end
		end	
		get!(dictCheckLi,listepossibles,1)
		get!(dictCheckCj,listepossibles,1)
		get!(dictCheckCarré,listepossibles,1)
		return false
	end
	function puces(liste, valdéfaut=nothing ; idPuces="p"*string(rand(Int)), classe="")
		début = """<span id="$idPuces" """ *(classe=="" ? ">" : """class="$classe">""")
		fin = """</span><script>const form = document.getElementById('$idPuces')
	form.oninput = (e) => { form.value = e.target.value; """ *
		(idPuces=="CacherRésultat" ? """if (e.target.value=='😉 Cachée') {
		document.getElementById('PossiblesEtSolution').classList.add('pasla');
		} else {
		document.getElementById('PossiblesEtSolution').classList.remove('pasla');
		};""" : "") * """}
							// and bubble upwards
	// set initial value:
	const selected_radio = form.querySelector('input[checked]');
	if(selected_radio != null) {form.value = selected_radio.value;}
	</script>"""
		inputs = ""
		for item in liste
			inputs *= """<span style="display:inline-block;"><input type="radio" id="$idPuces$item" name="$idPuces" value="$item" style="margin: O 4px 0 4px;" $(item == valdéfaut ? "checked" : "")><label style="margin: 0 18px 0 2px; user-select: none;" for="$idPuces$item">$item</label></span>"""
		end
		# for (item,valeur) in liste ### si liste::Array{Pair{String,String},1}
		# 	inputs *= """<input type="radio" id="$idPuces$item" name="$idPuces" value="$item" style="margin: 0 4px 0 20px;" $(item == valdéfaut ? "checked" : "")><label for="$idPuces$item">$valeur</label>"""
		# end
		return HTML(début * inputs * fin)
	end

	function htmlSudoku(JSudokuFini=jsvd(),JSudokuini=jsvd() ; toutVoir=true)
		if isa(JSudokuFini, String)
			return JSudokuFini
		else
			return HTML(raw"""<script id="scriptfini">
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
				// j'ai sabré volontairement cette partie 😄
			  const block = [Math.floor(i/3), Math.floor(j/3)];
			  const isEven = ((block[0]+block[1])%2 === 0);
			  const isMedium = (j%3 === 0);
			  const htmlCell = html`<td class='"""*(toutVoir ? raw"""${isInitial?"norbleu ":""}""" : raw"""${isInitial?"norbleu ":"grandblur blur "}""")*raw"""${isEven?"even-color":"odd-color"}' ${isMedium?'style="border-style:solid !important; border-left-width:medium !important;"':''}>${(value||'')}</td>`; // modifié légèrement
			  data[i][j] = value||0;
			  htmlRow.push(htmlCell);
			}
			const isMediumBis = (i%3 === 0);
    		htmlData.push(html`<tr ${isMediumBis?'style="border-style:solid !important; border-top-width:medium !important;"':''}>${htmlRow}</tr>`);
		  }
		  const _sudoku = html`<table id="sudokufini" """*(toutVoir ? "" : raw"""style="user-select: none;" """)*raw""">
			  <tbody>${htmlData}</tbody>
			</table>`  
		  // return {_sudoku,data};
		return _sudoku;
				};
		window.msga = (_sudoku) => {
				"""*(toutVoir ? "" : raw"""
		let tdbleus = _sudoku.querySelectorAll('td.norbleu');
  		tdbleus.forEach(tdbleu => {
			tdbleu.addEventListener('click', (e) => {
				var grantb = e.target.parentElement.parentElement;
				for(let grani=0; grani<9;grani++){ 
				for(let granj=0; granj<9;granj++){ 
				 if ( !(grantb.childNodes[grani].childNodes[granj].classList.contains("norbleu")) ) {
				grantb.childNodes[grani].childNodes[granj].classList.add("blur");
				
				} }};
			});
		});
		
		let tds = _sudoku.querySelectorAll('td.grandblur');
  		tds.forEach(td => {
				
			td.addEventListener('click', (e) => {
				e.target.classList.toggle("blur");
				
			});
		});	""")*raw"""
				
		  return _sudoku;

		};
		
		// sinon : return createSudokuHtml(...)._sudoku;
		return msga(createSudokuHtml(""" *"$JSudokuFini"*", "*"$JSudokuini"*""") );
		</script>""")
		end
	end
	htmls = htmlSudoku ## mini version
	htmat = htmlSudoku ∘ matriceàlisteJS ## mini version
	
	function chiffrePropal(mat,i,j) # Pour mise en forme en HTML mat3 : 3x3
		cp = chiffrePossible(mat,i,j)
		return matriceàlisteJS(reshape([((x in cp) ? x : 0) for x in 1:9], (3,3)),3)
	end
	const pt1 = "·" # "."
	const pt2 = "◌" # "○" # "◘" # "-" # ":"
	const pt3 = "●" # "■" # "▬" # "—" # "⁖" # "⫶"
	function nbPropal(mat,i,j) # Pour mise en forme en HTML mat3 : 3x3
		lcp = length(chiffrePossible(mat,i,j))
		if lcp == 0
			return [["↘","↓","↙"],["→","0","←"],["↗","↑","↖"]], 0
		else
			return matriceàlisteJS(reshape([(x == lcp ? string(x) : (x<lcp ? (lcp<4 ? pt1 : (lcp<7 ? pt2 : pt3)) : " ")) for x in 1:9], (3,3)),3), lcp
		end
	end
	function htmlSudokuPropal(JSudokuini=jsvd(),JSudokuFini=nothing ; toutVoir=true, parCase=true, somme=false)
		mS::Array{Int,2} = listeJSàmatrice(JSudokuini)
		if somme	
			mnPropal = fill(fill( fill("0",3),3) , (9,9) )
			mine = 10
			grisemine = [(0,0)]
			for i in 1:9, j in 1:9
				if mS[i,j] == 0
				mnPropal[i,j], lcp = nbPropal(mS, i, j)
					if lcp < mine
						mine = lcp
						grisemine = [(i,j)]
					elseif lcp == mine
						push!(grisemine, (i,j))
					end
				end
			end
			parCase = toutVoir
			toutVoir = true
			if 0 < mine < 9
				for (i,j) in grisemine
					mnPropal[i,j][3][3] = "✔"
				end
			end
			JPropal = matriceàlisteJS(mnPropal)
		else
			mPropal = fill(fill( fill(0,3),3) , (9,9) )
			for i in 1:9, j in 1:9
				if mS[i,j] == 0
					mPropal[i,j] = chiffrePropal(mS, i, j)
				end
			end
			JPropal = matriceàlisteJS(mPropal)
		end
			
		return HTML(raw"""<script id="scriptfini">
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
					const htmlMiniCell = html`<td class='mini"""*(toutVoir && parCase ? "'" : raw"""${isInitial?"'":" miniblur blur'"} """)*raw""" data-row="${pl}" data-col="${pj}">${(miniValue||' ')}</td>`; 
					htmlMiniRow.push(htmlMiniCell);
					}
					htmlMiniData.push(html`<tr style="border-style: none !important;">${htmlMiniRow}</tr>`);
				  }
				var mini_sudoku = html`<table class="minitab" """*(toutVoir && parCase ? "" : raw"""style="user-select: none;" """)*raw""">
			  <tbody>${htmlMiniData}</tbody>
			</table>`
				}
			  const valuee = mini_sudoku;
			  const block = [Math.floor(i/3), Math.floor(j/3)];
			  const isEven = ((block[0]+block[1])%2 === 0);
			  const isMedium = (j%3 === 0);
			  const htmlCell = html`<td class='${isInitial?"grandbleu ":""} ${isEven?"even-color":"odd-color"}' ${isMedium?'style="border-style:solid !important; border-left-width:medium !important;"':''} data-row="${i}" data-col="${j}">${(valuee||'')}</td>`;
			  data[i][j] = valuee||0;
			  htmlRow.push(htmlCell);
			}
			const isMediumBis = (i%3 === 0);
    		htmlData.push(html`<tr ${isMediumBis?'style="border-style:solid !important; border-top-width:medium !important;"':''}>${htmlRow}</tr>`);
		  }
		  const _sudoku = html`""" * (isa(JSudokuFini, String) ? raw"<h5 style='text-align: center;'> ⚡ Attention, sudoku initial à revoir ! </h5>" : raw"") * """<table id="sudokufini" """*(toutVoir && parCase ? "" : raw"""style="user-select: none;" """)*raw""">
			  <tbody>${htmlData}</tbody>
			</table>`  
			
		return _sudoku;
			};
			window.msga = (_sudoku) => {
				"""*(toutVoir && parCase ? "" : raw"""
		let tdbleus = _sudoku.querySelectorAll('td.grandbleu');
  		tdbleus.forEach(tdbleu => {
			tdbleu.addEventListener('click', (e) => {
				var grantb = e.target.parentElement.parentElement;
				for(let grani=0; grani<9;grani++){ 
				for(let granj=0; granj<9;granj++){ 
				 if (grantb.childNodes[grani].childNodes[granj].childNodes[0].childNodes[1]!=null) {
				for(let minii=0; minii<3;minii++){ 
				for(let minij=0; minij<3;minij++){ 
				grantb.childNodes[grani].childNodes[granj].childNodes[0].childNodes[1].childNodes[minii].childNodes[minij].classList.add("blur");
				
				}} } }};
			});
		});
				
		let tds = _sudoku.querySelectorAll('td.miniblur');
  		tds.forEach(td => {
			
			"""*(parCase ? raw"""
			td.addEventListener('click', (e) => {
				e.target.parentElement.parentElement.childNodes.forEach(ligne => {
				  ligne.childNodes.forEach(colo => {
					colo.classList.toggle("blur");
				  });
				}); 
			});	
				""" : (toutVoir ? raw"""	
			td.addEventListener('click', (e) => {
				const ilig = e.target.getAttribute('data-row');
				const jcol = e.target.getAttribute('data-col'); 
					e.target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.childNodes.forEach(tr => {
					tr.childNodes.forEach(tdd => {

						if (tdd.childNodes[0].childNodes[1]!=null){
				tdd.childNodes[0].childNodes[1].childNodes[ilig].childNodes[jcol].classList.toggle("blur");
					}});
				});		
			}); """ : raw"""
			
			td.addEventListener('click', (e) => {
				const ilig = e.target.getAttribute('data-row');
				const jcol = e.target.getAttribute('data-col'); 
				const granlig = e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-row');
				const grancol = e.target.parentElement.parentElement.parentElement.parentElement.getAttribute('data-col'); 
				const orNicar = (tlig,tcol) => MMcar(granlig,grancol,tlig,tcol);
					e.target.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.childNodes.forEach(tr => {
					tr.childNodes.forEach(tdd => {

						if (tdd.childNodes[0].childNodes[1]!=null) {
							for(let minii=0; minii<3;minii++){ 
							for(let minij=0; minij<3;minij++){ 
							 if (ilig==minii&&jcol==minij ) {
							tdd.childNodes[0].childNodes[1].childNodes[minii].childNodes[minij].classList.add("blur");
						}}} };

						if ((tdd.childNodes[0].childNodes[1]!=null) && (tdd.getAttribute('data-row') == granlig || tdd.getAttribute('data-col') == grancol || orNicar(tdd.getAttribute('data-row'),tdd.getAttribute('data-col')) )){

							tdd.childNodes[0].childNodes[1].childNodes[ilig].childNodes[jcol].classList.toggle("blur");
							} });
				});		
			}); """))*raw"""
	
		});	""")*raw"""
				
		  return _sudoku;

		};
		
		// sinon : return createSudokuHtml(...)._sudoku;
		return msga(createSudokuHtml(""" *"$JPropal"*", "*"$JSudokuini"*"""));
		</script>""")
	end
	htmlsp = htmlSudokuPropal ## mini version
	htmatp = htmlSudokuPropal ∘ matriceàlisteJS ## mini version

	suivant(nombre::Int,relance::Int) = nombre + 1_345 # * (relance<2 ? 0 : 1)
######################################################################################
  function résoutSudoku(JSudoku::Vector{Vector{Int}} ; nbToursMax::Int = 203, nbEssaisMax::Int = 4, essai::Int = 1, fsuiv::Function = suivant) 
	nbTours = 0 # cela compte les tours si choisi bien (avec un léger décalage)
	nbToursTotal = 0 # le nombre qui ce programme a réellement fait par essai
	
	mS::Array{Int,2} = listeJSàmatrice(JSudoku) # Converti en vraie matrice
	lesZéros = shuffle!([(i,j) for i in 1:9, j in 1:9 if mS[i,j]==0]) # Fast & Furious
	
	# listeHistoChoix = []  ## histoire 0
	# listeHistoMat = []  ## histoire 0
	# listeHistoToursTotal = []  ## histoire 0
	# nbHistoTot = 0  ## histoire 0
	listedechoix = []
	listedancienneMat = []
	listedesZéros = []
	listeTours = Int[]
	nbChoixfait = 0
	minChoixdesZéros = 10
	allerAuChoixSuivant = false
	choixPrécédent = false
	choixAfaire = false
	if essai>1 || vérifSudokuBon(mS)
		while length(lesZéros)>0 && nbToursTotal <= nbToursMax
			çaNavancePas = true # Permet de voir si rien ne se remplit en un tour
			minChoixdesZéros = 10
			nbTours += 1
			nbToursTotal += 1
			lesClésZérosàSuppr=Int[]
			vérifligne = [ Dict{Set{Int}, Int}() for _ = 1:9 ]
			vérifcol = [ Dict{Set{Int}, Int}() for _ = 1:9 ]
			vérifcarré = [ Dict{Set{Int}, Int}() for _ = 1:9 ]
			if !allerAuChoixSuivant
				for (key, (i,j)) in enumerate(lesZéros)
					listechiffre = chiffrePossible(mS,i,j)
					if isempty(listechiffre) || (essai>2 && pasAssezDePropal!(listechiffre, vérifligne[i], vérifcol[j], vérifcarré[kelcarré(i,j)]) ) # Plus de possibilité (ou pas assez)... pas bon signe ^^
						allerAuChoixSuivant = true # donc mauvais choix
						break
					elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
						mS[i,j]=collect(listechiffre)[1]
						# mS[i,j]=pop!(listechiffre) ## Je ne sais pas :( marche pas
						push!(lesClésZérosàSuppr, key)
						çaNavancePas = false # Car on a réussi à remplir
					elseif çaNavancePas && length(listechiffre) < minChoixdesZéros
						minChoixdesZéros = length(listechiffre)
						choixAfaire = (i,j, 1, minChoixdesZéros, listechiffre) # On garde les cellules avec le moins de choix à faire, si ça n'avance pas
					end
				end
			end
			if çaNavancePas || allerAuChoixSuivant # Pour avancer autrement ^^
				if allerAuChoixSuivant # Si le choix en cours n'est pas bon
					if choixPrécédent==false || isempty(listedechoix)# pas de bol hein
						return " ⚡ Sudoku impossible", md"""#### ⚡ Sudoku impossible à résoudre... et à me piéger aussi 😜
							
		Si ce n'est pas le cas, revérifier le Sudoku initial, car celui-ci n'a pas de solution possible.
							
		Par exemple : si une case est trop contrainte, qui attend uniquement pour la ligne un 1, et en colonne autre chiffre que 1, comme 9 ← il n'y aura donc aucune solution, car on ne peut pas mettre à la fois 1 et 9 dans une seule case : c'est impossible à résoudre... comme ce sudoku initial.""", 
(tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat) 
# (tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat ,histoix=listeHistoChoix,histrice=listeHistoMat, histour=listeHistoToursTotal,histo=nbHistoTot) ## retours d'histoires 3
					elseif choixPrécédent[3] < choixPrécédent[4] # Aller au suivant
						# push!(listeHistoMat , copy(mS)) ## histoire 1 
						# push!(listeHistoChoix , choixPrécédent) ## histoire 1 
						# push!(listeHistoToursTotal , (nbTours, nbToursTotal)) ## histoire 1 
						# nbHistoTot += 1 ## histoire 1
						(i,j, choix, l, lc) = choixPrécédent
						choixPrécédent = (i,j, choix+1, l, lc)
						listedechoix[nbChoixfait] = choixPrécédent
						mS = copy(listedancienneMat[nbChoixfait])
						nbTours = listeTours[nbChoixfait]
						allerAuChoixSuivant = false
						mS[i,j] = pop!(lc)
						lesZéros = copy(listedesZéros[nbChoixfait])
					elseif length(listedechoix) < 2 # pas 2 bol
						return " ⚡ Sudoku impossible", md"""#### ⚡ Sudoku impossible à résoudre... et à me piéger aussi 😜
							
		Si ce n'est pas le cas, revérifier le Sudoku initial, car celui-ci n'a pas de solution possible.
							
		Par exemple : si une case est trop contrainte, qui attend uniquement pour la ligne un 1, et en colonne autre chiffre que 1, comme 9 ← il n'y aura donc aucune solution, car on ne peut pas mettre à la fois 1 et 9 dans une seule case : c'est impossible à résoudre... comme ce sudoku initial.""", 
(tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat) 
# (tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat ,histoix=listeHistoChoix,histrice=listeHistoMat, histour=listeHistoToursTotal,histo=nbHistoTot) ## retours d'histoires 3
					else # Il faut revenir d'un cran dans la liste historique
						deleteat!(listedechoix, nbChoixfait)
						deleteat!(listedancienneMat, nbChoixfait)
						deleteat!(listedesZéros, nbChoixfait)
						deleteat!(listeTours, nbChoixfait)
						nbChoixfait -= 1
						choixPrécédent = listedechoix[nbChoixfait]
						nbTours = listeTours[nbChoixfait]
					end
				else # Nouveau choix à faire et à garder en mémoire
					# push!(listeHistoMat , copy(mS)) ## histoire de 
					# push!(listeHistoChoix , choixAfaire) ## histoire 2 
					# push!(listeHistoToursTotal , (nbTours, nbToursTotal)) ## histoire 2 
					# nbHistoTot += 1 ## histoire 2
					push!(listedechoix, choixAfaire) # ici pas besoin de copie
					push!(listedancienneMat , copy(mS)) # copie en dur
					filter!(!=(choixAfaire[1:2]), lesZéros) # On retire ce que l'on a choisi de faire
					push!(listedesZéros , copy(lesZéros)) # copie en dur aussi
					push!(listeTours, nbTours) # On garde tout en mémoire
					nbChoixfait += 1
					mS[choixAfaire[1:2]...] = pop!(choixAfaire[5])
					choixPrécédent = choixAfaire
				end 
			else # !çaNavancePas && !allerAuChoixSuivant ## Tout va bien ici
				deleteat!(lesZéros, lesClésZérosàSuppr) # On retire ceux remplis
			end	
		end
		else return "🧐 Merci de corriger ce Sudoku ;)", md"""#### 🧐 Merci de revoir ce sudoku, il n'est pas conforme : 
			En effet, il doit y avoir au moins sur une ligne ou colonne ou carré, un chiffre en double; bref au mauvais endroit ! 😄""", 
(tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat) 
# (tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat ,histoix=listeHistoChoix,histrice=listeHistoMat, histour=listeHistoToursTotal,histo=nbHistoTot) ## retours d'histoires 3
	end
	if essai > nbEssaisMax
		return "🤓 Merci de mettre un peu plus de chiffres... sudoku sûrement impossible ;)", md"""#### 🤓 Merci de mettre plus de chiffres ;) 
			
		En effet, bien que ce [Plutoku](https://github.com/4LD/plutoku) est quasi-parfait* 😄, certains cas (très rare bien sûr) peuvent mettre du temps (plus de 3 secondes) que je vous épargne ;)
		
		Il y a de forte chance que votre sudoku soit impossible... sinon, merci de me le signaler, car normalement ce cas arrive moins souvent que gagner au Loto ^^ 
		
		_* Sauf erreur de votre humble serviteur_""", 
(tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat) 
# (tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat ,histoix=listeHistoChoix,histrice=listeHistoMat, histour=listeHistoToursTotal,histo=nbHistoTot) ## retours d'histoires 3
	elseif nbToursTotal > nbToursMax
		return résoutSudoku(JSudoku ; nbToursMax=fsuiv(nbToursMax,essai), nbEssaisMax=nbEssaisMax, essai=essai+1) 
	else
		# push!(listeHistoMat , copy(mS)) ## toute l'histoire		
		# push!(listeHistoChoix , choixPrécédent) ## toute l'histoire	
		# push!(listeHistoToursTotal , (nbTours, nbToursTotal)) ## toute l'histoire 
		# nbHistoTot += 1 ## toute l'histoire	
		### return matriceàlisteJS(mS') ## si on utilise : listeJSàmatrice(...)'
		return matriceàlisteJS(mS), md"**Pour résoudre ce sudoku :** il a fallu faire **$nbChoixfait choix** et **$nbTours $((nbTours>1) ? :tours : :tour)** (si on savait à l'avance les bons choix), ce programme ayant fait _**$nbToursTotal $((nbToursTotal>1) ? :tours : :tour) au total**_ en $(essai) $((essai>1) ? :essais : :essai) !!! 😃", 
(tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat) 
# (tour=nbTours,tt=nbToursTotal,essai=essai,noix=nbChoixfait,tours=listeTours,choix=listedechoix, zéros=listedesZéros,maths=listedancienneMat ,histoix=listeHistoChoix,histrice=listeHistoMat, histour=listeHistoToursTotal,histo=nbHistoTot) ## retours d'histoires 3
	end
  end
  rjs = résoutSudoku ## mini version
  rmat = résoutSudoku ∘ matriceàlisteJS ## mini version
######################################################################################

######################################################################################
# 4LD : Pour pouvoir venir et générer des Sudoku Aléatoire aussi
  function sudokuAléatoireFini() 
	nbTours = 0 # cela compte les tours si choisi bien (avec un léger décalage)
	nbToursTotal = 0 # le nombre qui ce programme a réellement fait
	nbToursMax = 203
	
	mS::Array{Int,2} = zeros(Int, 9,9) # Matrice de zéro
	lesZéros = shuffle!([(i,j) for i in 1:9, j in 1:9 if mS[i,j]==0])# Fast & Furious
	
	listedechoix = []
	listedancienneMat = []
	listedesZéros = []
	listeTours = Int[]
	nbChoixfait = 0
	minChoixdesZéros = 10
	allerAuChoixSuivant = false
	choixPrécédent = false
	choixAfaire = false
	while length(lesZéros)>0 && nbToursTotal < nbToursMax
		çaNavancePas = true # Permet de voir si rien ne se remplit en un tour
		minChoixdesZéros = 10
		nbTours += 1
		nbToursTotal += 1
		lesClésZérosàSuppr=Int[]
		if !allerAuChoixSuivant
			for (key, (i,j)) in enumerate(lesZéros)
				listechiffre = chiffrePossible(mS,i,j)
				if isempty(listechiffre) ### Plus de possibilité (ou pas assez)... pas bon signe ^^
					allerAuChoixSuivant = true # donc mauvais choix
					break
				elseif length(listechiffre) == 1 # L'idéal, une seule possibilité
					mS[i,j]=collect(listechiffre)[1]
					# mS[i,j]=pop!(listechiffre) ## Je ne sais pas :( marche pas
					push!(lesClésZérosàSuppr, key)
					çaNavancePas = false # Car on a réussi à remplir
				elseif çaNavancePas && length(listechiffre) < minChoixdesZéros
					minChoixdesZéros = length(listechiffre)
					choixAfaire = (i,j, 1, minChoixdesZéros, listechiffre) # On garde les cellules avec le moins de choix à faire, si ça n'avance pas
				end
			end
		end
		if çaNavancePas || allerAuChoixSuivant # Pour avancer autrement ^^
			if allerAuChoixSuivant # Si le choix en cours n'est pas bon
				if choixPrécédent[3] < choixPrécédent[4] # Aller au suivant
					(i,j, choix, l, lc) = choixPrécédent
					choixPrécédent = (i,j, choix+1, l, lc)
					listedechoix[nbChoixfait] = choixPrécédent
					mS = copy(listedancienneMat[nbChoixfait])
					nbTours = listeTours[nbChoixfait]
					allerAuChoixSuivant = false
					mS[i,j] = pop!(lc)
					lesZéros = copy(listedesZéros[nbChoixfait])
				else # Il faut revenir d'un cran dans la liste historique
					deleteat!(listedechoix, nbChoixfait)
					deleteat!(listedancienneMat, nbChoixfait)
					deleteat!(listedesZéros, nbChoixfait)
					deleteat!(listeTours, nbChoixfait)
					nbChoixfait -= 1
					choixPrécédent = listedechoix[nbChoixfait]
					nbTours = listeTours[nbChoixfait]
				end
			else # Nouveau choix à faire et à garder en mémoire
				push!(listedechoix, choixAfaire) # ici pas besoin de copie
				push!(listedancienneMat , copy(mS)) # copie en dur
				filter!(!=(choixAfaire[1:2]), lesZéros) # On retire ce que l'on a choisi de faire
				push!(listedesZéros , copy(lesZéros)) # copie en dur aussi
				push!(listeTours, nbTours) # On garde tout en mémoire
				nbChoixfait += 1
				mS[choixAfaire[1:2]...] = pop!(choixAfaire[5])
				choixPrécédent = choixAfaire
			end 
		else # !çaNavancePas && !allerAuChoixSuivant ## Tout va bien ici
			deleteat!(lesZéros, lesClésZérosàSuppr) # On retire ceux remplis
		end	
	end
	if nbToursTotal > nbToursMax
		return sudokuAléatoireFini() # Normalement, il ne passe peu par ici
	else
		return mS
		# return matriceàlisteJS(mS)
	end
  end
  function sudokuAléatoire(x=19:62 ; fun=rand, matzéro=sudokuAléatoireFini())
	# x=rand(1:81)) ## Pas besoin d'aller si fort
	if !isa(x, Int) # Permet de choisir le nombre de zéro ou un intervale
		x=fun(x)
	end
	x = (0 < x < 82) ? x : 81 # Pour ceux aux gros doigts, ou qui voit trop grand
	liste = shuffle!([(i,j) for i in 1:9 for j in 1:9])
	for (i,j) in liste[1:x] # nbApproxDeZéros
		matzéro[i,j] = 0
	end
	return matriceàlisteJS(matzéro)
  end

  function vieuxSudoku!(nouveau=sudokuAléatoire() ; défaut=false, mémoire=SudokuMémo, matzéro=sudokuAléatoireFini(), idLien="lien"*string(rand(Int)))
	if défaut==true # Mégalomanie # On revient à mon défaut
		mémoire[2] = copy(mémoire[4])
	elseif isa(nouveau, Int) || isa(nouveau, UnitRange{Int})
		mémoire[2] = sudokuAléatoire(nouveau ; matzéro=matzéro)
	elseif nouveau==mémoire[1] 
		mémoire[2] = sudokuAléatoire()
	else mémoire[2] = copy(nouveau) # Astuce pour sauver le sudoku en cours
	end
	return HTML("""<script>
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
  vieux = vs = vs! = vS! = vieuxSudoku! ## mini version
  vsd() = vieuxSudoku!(défaut=true) ## Pour revenir à l'original
  ini = défaut = defaut = vsd ## mini version

  function sudokuAlt(nbChiffresMax=rand(26:81), moinsOK=true, nbessai=1) 
	nbTours = 0 # cela compte les tours si choisi bien (avec un léger décalage)
	nbToursTotal = 0 # le nombre qui ce programme a réellement fait
	nbToursMax = 203
	nbChiffres = 1
	
	mS::Array{Int,2} = zeros(Int, 9,9) # Matrice de zéro
	lesZéros = shuffle!([(i,j) for i in 1:9, j in 1:9 if mS[i,j]==0])# Fast & Furious
	
	for (i,j) in lesZéros
		if nbChiffres > nbChiffresMax
			return mS
		else 
		listechiffre = chiffrePossible(mS,i,j)
			if isempty(listechiffre) ### Pas bon signe ^^
				if moinsOK || nbessai > 26
					return mS
				else 
					return sudokuAlt(nbChiffresMax, false, nbessai+1)
				end
			else length(listechiffre) == 1 # L'idéal, une seule possibilité
				mS[i,j]=collect(listechiffre)[1]
				nbChiffres += 1
			end
		end
	end
  end
  salt = sudokuAlt ## mini version

  function blindtest(nbtest=100 ; tmax=203, emax=4, emin=1, fsuiv=suivant, nbzéro = (rand, 7:77), sudf=sudokuAléatoireFini)
	nbzérof() = isa(nbzéro,Tuple) ? nbzéro=nbzéro[1](nbzéro[2]) : Nothing
	for i in 1:nbtest
		sudini = sudf()
		nbzérof()
		sudaléa = sudokuAléatoire(nbzéro, fun=identity, matzéro=copy(sudini))
		# try 
		# 	résoutSudoku(sudaléa ; nbToursMax=tmax,nbEssaisMax=emax,essai=emin, fsuiv=fsuiv)
		# catch e
		# 	return ("bug", e, sudaléa)
		# end
		soluce = résoutSudoku(sudaléa ; nbToursMax=tmax,nbEssaisMax=emax,essai=emin, fsuiv=fsuiv)
		if soluce[1] isa String
			if sudf==sudokuAléatoireFini || soluce[1] != " ⚡ Sudoku impossible"
		# if soluce[1] == " ⚡ Sudoku impossible"
		# if soluce[1] == "🧐 Merci de corriger ce Sudoku ;)"
		# if soluce[1] == "🤓 Merci de mettre un peu plus de chiffres... sudoku sûrement impossible ;)"
				return i, nbzéro, soluce, sudini, replace("vieux( $(matriceàlisteJS(sudini)) )"," "=>""), sudaléa, replace("vieux($sudaléa)"," "=>"")
			end
		end
	end
	return "Tout va bien... pour le moment 🤓"
  end
  bt = testme = blindtest ## mini version
######################################################################################
end; nothing; # stylélàbasavecbonus! ## voir juste dans la cellule #Bonus au dessus ↑
# Voilà ! fin de la plupart du code de ce programme Plutoku.jl

# ╔═╡ 96d2d3e0-2133-11eb-3f8b-7350f4cda025
md"# Résoudre un Sudoku par Alexis $cool" # v1.8.3 lundi 28/06/2021 🤟

#= Pour la vue HTML et le style CSS, cela est fortement inspiré de https://github.com/Pocket-titan/DarkMode et pour le sudoku https://observablehq.com/@filipermlh/ia-sudoku-ple1
Pour basculer entre plusieurs champs automatiquement via JavaScript, merci à https://stackoverflow.com/a/15595732 , https://stackoverflow.com/a/44213036 et autres
Et bien sûr le calepin d'exemple de @fonsp "3. Interactivity"
Pour info, le code principal et stylélàbasavecbonus! :)

Ce "plutoku" est visible sur https://github.com/4LD/plutoku

Pour le relancer, c'est sur https://mybinder.org/v2/gh/fonsp/pluto-on-binder/master?urlpath=pluto/open?url=https://raw.githubusercontent.com/4LD/plutoku/main/Plutoku.jl
Ou https://binder.plutojl.org/open?url=https:%252F%252Fraw.githubusercontent.com%252F4LD%252Fplutoku%252Fmain%252FPlutoku.jl =#

# ╔═╡ 81bbbd00-2c37-11eb-38a2-09eb78490a16
md"""Si besoin, dans cette session, le sudoku en cours (ci-dessous) peut rester en mémoire en cliquant sur le bouton suivant : $(@bind boutonSudokuInitial html"<input type=button style='margin: 0 10px 0 10px;' value='En cours → Le sudoku initial ;)'>") *( si vide → sudoku aléatoire )*"""

# ╔═╡ caf45fd0-2797-11eb-2af5-e14c410d5144
begin 
	boutonSudokuInitial # Remettre le puce "ModifierInit" sur Le sudoku initial ;)
	vieuxSudoku!(SudokuMémo[3]) # Permet de le remplacer par celui modifié
end; md""" $(@bind viderOupas puces(["Vider le sudoku initial","Le sudoku initial ;)"],"Le sudoku initial ;)"; idPuces="ModifierInit")) $(html" <a href='#Bonus' style='padding-left: 10px; border-left: medium dashed #777;'>Bonus plus bas ↓</a>") : vieux sudoku et astuces
"""

# ╔═╡ a038b5b0-23a1-11eb-021d-ef7de773ef0e
begin
	viderOupas isa Missing ? viderSudoku = 2 : (viderSudoku = (viderOupas == "Vider le sudoku initial" ? 1 : 2))
	SudokuInitial = HTML("""
<script>
// stylélàbasavecbonus!

const premier = JSON.stringify( $(SudokuMémo[1]) );
const deuxième = JSON.stringify( $(SudokuMémo[2]) );
const defaultFixedValues = $(SudokuMémo[viderSudoku])""" * raw"""
			
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
      const htmlInput = html`<input  
        type='text'
        data-row='${i}'
        data-col='${j}'
        maxlength='1' 
        value='${(value||'')}'
      >`;
      const block = [Math.floor(i/3), Math.floor(j/3)];
      const isEven = ((block[0]+block[1])%2 === 0);
	  const isMedium = (j%3 === 0);
      const htmlCell = html`<td class='${isEven?"even-color":"odd-color"}' ${isMedium?'style="border-style:solid !important; border-left-width:medium !important;"':""}>${htmlInput}</td>`
      data[i][j] = value||0;
      htmlRow.push(htmlCell);
    }
	
    const isMediumBis = (i%3 === 0);
    htmlData.push(html`<tr ${isMediumBis?'style="border-style:solid !important; border-top-width:medium !important;"':""}>${htmlRow}</tr>`);
  }
  const _sudoku = html`<table id="sudokincipit" vrai="test" sudata=${JSON.stringify(data)} >
      <tbody>${htmlData}</tbody>
    </table>`  
  return {_sudoku,data};
  // // return _sudoku ;
  
}

window.sudokuViewReactiveValue = ({_sudoku:html, data}) => {
// // window.sudokuViewReactiveValue = (html) => {
// // data = JSON.parse(html.getAttribute("sudata"));
  html.addEventListener('input', (e)=>{
    e.stopPropagation();
    e.preventDefault();
    html.value = data
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
			moveDown(e);
			break;
		case "ArrowUp":
			moveUp(e);
			break;
		case "ArrowLeft":
			moveLeft(e);
			break;
		case "ArrowRight":
			moveRight(e);
			break;
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
			(e.key==="Delete")?(da.selectionStart = da.selectionEnd = da.value.length):(da.selectionStart = da.selectionEnd = 0); // select KO :(
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
		'\&':1,é:2,'\"':3,"\'":4,'\(':5,'\-':6,è:7,_:8,ç:9};

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
			e.stopPropagation();
			e.preventDefault();
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
		
  }) 
  var ele = document.getElementsByName("ModifierInit");
  const jdata = JSON.stringify(data);
  if (jdata == premier) {
	ele[0].checked = true;
  } else if (jdata == deuxième) {
	ele[1].checked = true; // ...].click(); // était KO...
  }
  html.setAttribute('sudata', jdata);
  html.dispatchEvent(new Event('input'));
  return html;

};

return sudokuViewReactiveValue(createSudokuHtml(defaultFixedValues));
</script>""")
	@bind bindJSudoku SudokuInitial
end

# ╔═╡ 7cce8f50-2469-11eb-058a-099e8f6e3103
vaetvient = HTML(raw"""
<script>
var vieillecopie = false;

function déjàvu() { 
	var père = document.getElementById("sudokincipit").parentElement;
	var fils = document.getElementById("copiefinie");
	var ancien = document.getElementById("sudokufini");
	if (vieillecopie.isEqualNode(ancien)) {
		ancien.innerHTML = fils.innerHTML;
		ancien.removeChild(ancien.querySelector("tfoot"));
		msga(ancien);
	}
	document.getElementById("sudokincipit").hidden = false;
	père.removeChild(fils);
	document.getElementById("va_et_vient").innerHTML = `Sudoku initial ⤴ (modifiable) et sa solution : `
};

function làhaut() { 
	var père = document.getElementById("sudokincipit").parentElement;
	var fils = document.getElementById("copiefinie");
	var copie = document.getElementById("sudokufini");
	fils ? père.removeChild( fils ) : true;
	document.getElementById("sudokincipit").hidden = true;
	var tabl = document.createElement("table");
	vieillecopie = (copie ? copie.cloneNode(true) : tabl);
	tabl.id = "copiefinie";
	tabl.innerHTML = (copie ? copie.innerHTML : `<thead id='taide'><tr><th>Aucune solution 😜 ou c'est coché  <code>😉 Cachée</code><br><br></th></tr></thead>`) + `<tfoot id='tesfoot'><tr id='lignenonvisible'><th colspan="9">↪ Cliquer ici pour revenir au sudoku modifiable</th></tr></tfoot>`;
	père.appendChild(tabl);
	document.getElementById("taide") ? document.getElementById("taide").addEventListener("click", déjàvu) : true;
	document.getElementById("tesfoot").addEventListener("click", déjàvu);
	copie ? msga(document.getElementById("copiefinie")) : true;
	document.getElementById("va_et_vient").innerHTML = `Solution ↑ (au lieu du sudoku modifiable initial)`
};
document.getElementById("va_et_vient").addEventListener("click", làhaut);

</script><span id="va_et_vient">"""); bindJSudoku; md"""#### $vaetvient Sudoku initial ⤴ (modifiable) et sa solution : $(html"</span>") """

# ╔═╡ bba0b550-2784-11eb-2f58-6bca9b1260d0
md"""$(@bind voirOuPas puces(["😉 Cachée", "En touchant, entrevoir les nombres…","Pour toutes les cases, voir les nombres…"],"😉 Cachée"; idPuces="CacherRésultat") ) 
$(html"<div style='margin: 2px; border-bottom: medium dashed #777;'></div>")
                                                
$(@bind PropalOuSoluce puces(["…par chiffre possible", "…de possibilités (min ✔)","…par case 🔢","…de la solution 🚩"],"…par chiffre possible"; idPuces="PossiblesEtSolution", classe="pasla" ) )"""

# ╔═╡ b2cd0310-2663-11eb-11d4-49c8ce689142
bindJSudoku isa Missing ? sudokuSolution = résoutSudoku(SudokuMémo[3]) : (SudokuMémo[3] = bindJSudoku; #= Pour que le sudoku en cours (initial modifié) reste en mémoire si besoin -> Le sudoku initial ;) =# sudokuSolution = résoutSudoku(bindJSudoku)); sudokuSolution[2] # La petite explication seule

# ╔═╡ 4c810c30-239f-11eb-09b6-cdc93fb56d2c
if bindJSudoku isa Missing || voirOuPas isa Missing || voirOuPas=="😉 Cachée"
	md"""$(typeof(sudokuSolution[1])==String ? html"<h5 style='text-align: center;'> ⚡ Attention, sudoku initial à revoir ! </h5>"  : md"###### 🤐 Le sudoku est caché pour le moment comme demandé")
Bonne chance ! Si besoin, cocher `😉 Cachée` pour revoir ce message .

Pour information, `En touchant, entrevoir les nombres…` permet en cliquant de faire apparaître (et disparaître via les chiffres bleus) le contenu choisi, comme un coup de pouce. De plus : 

   - En cliquant précisément dans une case, sur le 1 (en haut à gauche) au 9 (en bas à droite; le chiffre 5 est donc au milieu), les nombres `…par chiffre possible` permettent de voir si le chiffre est possible dans la case et ses cases liées (sur sa ligne, sa colonne et son carré).
   - Chaque case à un seul nombre `…de possibilités (min ✔)` de 1 à 9 (de façon similaire, de haut en bas dans la case). Celles ayant le moins de possibilités ont ✔ en bas à droite (à la place du 9).
   - Les nombres `…par case 🔢` permettent de voir la liste complète des chiffres possibles par case.
   - Seuls les nombres `…de la solution 🚩` montrent (un ou) des chiffres du sudoku fini.

Bien sûr, il y a pour chaque catégorie : 
`Pour toutes les cases, voir les nombres…` pour tout voir."""
elseif PropalOuSoluce == "…de la solution 🚩" # || PropalOuSoluce isa Missing
	htmlSudoku(sudokuSolution[1],bindJSudoku ; toutVoir= (voirOuPas=="Pour toutes les cases, voir les nombres…") )
else htmlSudokuPropal(bindJSudoku,sudokuSolution[1] ; toutVoir= (voirOuPas=="Pour toutes les cases, voir les nombres…"), parCase= (PropalOuSoluce =="…par case 🔢"), somme= (PropalOuSoluce=="…de possibilités (min ✔)"))
end

# ╔═╡ e986c400-60e6-11eb-1b57-97ba3089c8c1
stylélàbasavecbonus = HTML(raw"""<script>
const plutôtnoir = `<style>

/*///////////  Pour Pluto.jl  //////////////*/

	body {
		// background-color: hsl(0, 0%, 15%);
    	background-color: hsl(0, 0%, 0%);
	}
	// main {
		// max-width: 900px;
	// }

	body > header, footer, pluto-helpbox > header {
    	background-color: hsl(0, 0%, 8%);
		color: hsl(0, 0%, 90%);
	}
	body > header * {
		color: white;
	}
	preamble {
		filter: invert(1);
	}
	nav#at_the_top img {
		 filter: invert(1) hue-rotate(180deg) brightness(0.8) saturate(1.1);
	}
	nav#at_the_top button.toggle_export,
	nav#undo_delete {
		filter: invert(1);
	}
	body.disconnected > header {
		background-color: hsla(18, 35%, 47%, 50%);
	}
	pluto-input > button {
		filter: invert(1);
	}
	pluto-output {
		background-color: hsl(229, 5%, 10%);
		color: hsl(0, 0%, 90%);
	}
	pluto-output h1,
	pluto-output h2,
	pluto-output h3,
	pluto-output h4,
	pluto-output h5,
	pluto-output h6 {
		color: hsl(0, 0%, 90%);
	}
	pluto-output code {
		color: hsl(0, 0%, 80%)
	}
	pluto-output a {
		filter: invert(1);
	}
	pluto-output jltree, jltree *, jltree * * {
		filter: brightness(5);
	}
	nav#at_the_top img {
		filter: invert(1) hue-rotate(180deg) contrast(0.85);
	}
	jlerror > header {
		color: hsl(348, 40%, 90%);
	}
	pluto-filepicker .cm-s-material-palenight .cm-operator {
		color: #ff3b00;
	}
	jltree::before, jltree::after {
		filter: invert(1);
	}
	header.show_export header, header.show_export b {
		color: initial;
	}
	cell>button,
	cellinput>button,
	runarea>button,
	cellshoulder>button,
	slide-controls>button {
		color: white;
	}
	pluto-shoulder > button > span::after,
	pluto-cell.code_folded > pluto-shoulder > button > span::after {
		filter: invert(1);
	}
	pluto-cell > button {
		filter: invert(1);
	}
	cell.running > trafficlight {
		background: repeating-linear-gradient(-45deg,
		hsla(20, 20%, 80%, 1),
		hsla(20, 20%, 80%, 1) 8px,
		hsla(20, 20%, 80%, 0.1) 8px,
		hsla(20, 20%, 80%, 0.1) 16px);
	}
	cell.running.error > trafficlight {
		background: repeating-linear-gradient(-45deg,
            hsl(0, 100%, 71%),
            hsl(0, 100%, 71%) 8px,
            hsla(12, 71%, 47%, 0.33) 8px,
            hsla(12, 71%, 47%, 0.33) 16px);
	}
	pluto-runarea {
		filter: invert(1) brightness(1.9) contrast(1);
	}
	pluto-helpbox {
		color: hsl(0, 0%, 90%);
		background-color: hsl(0, 0%, 10%);
	}
	footer a {
		color: hsl(0, 0%, 95%);
	}
	footer input {
		background-color: hsl(0, 0%, 13%);
    	color: hsl(0, 0%, 85%);
	}
	pluto-helpbox > header > button {
		background: grey !important;
	}
	button {
		background-color: darkgrey;
	}
	div {
		background-color: #000000;
		color: #ded8d8;
	}
	a {
		color: #656060;
	}
	pluto-helpbox > section pre {
		background-color: #2f2f2f;
	}
	nav#at_the_top > #process_status {
		color: black;
		filter: invert(1);
	}
/*///////////  Pour le sudoku  //////////////*/

#taide,
#tesfoot,
#va_et_vient {
	user-select: none;
}
// #sudokufini {cursor: pointer;}
select{
  padding:10px;
}
table{
  width:0 !important;
  height:0 !important;
}
pluto-output table {
    border: medium hidden #000 !important;
	margin-block-start: 0;
	margin-block-end: 0;
}
pluto-output table.minitab {
	border-spacing: 0 !important;
    border: 0 !important;
	// margin: 1px !important;
	margin: auto !important;
}
tr {
  border:0 !important;
  width:0
}

td.even-color{
	background-color:#000; /* noir */
	text-align:center;
	font-size:14pt;
	width:38px; 
  	height:38px;
	border:1px solid #ccc; /* noir */
	// border:1px solid black;
	padding: 0;
}

td.odd-color{
	background-color:#222; /* noir */
	// background-color:#f2f2f2;
	text-align:center;
	font-size:14pt;
	border:1px solid #ccc; /* noir */
	// border:1px solid black;
	width:38px; 
  	height:38px;	
	padding: 0;			  
}
input#pour-définir-le-sudoku-initial {
	background-color:transparent;
	border:0;
	margin-left:6px;
}
td input{
  text-align:center;
  font-size:14pt;
  width:100% !important;
  height:100% !important;
  background-color:transparent;
  border:0;
	color:#aaa; /* noir */
}
td { min-width: 38px; }

pluto-output table tr td.blur{
	color: transparent;
	user-select: none;
	// filter: blur(5px);
}

td.mini{
	min-width:15px; 
	// height:15px;
	// color: #b39700;
	padding: 0;
}
.minitab tbody tr:nth-child(2n+1) td:nth-child(2n+1) {
	color: #e6c300; /* noir */
	// color: #af0000;
	// 1 3 7 9
}
.minitab tbody tr:nth-child(2n) td:nth-child(2n) {
	color: #e6c300; /* noir */
	// color: #af0000;
	// 5
}
.minitab tbody tr:nth-child(2n+1) td:nth-child(2n) {
	color: #b39700; /* noir */
	// color: #da0000;
	// 2 8
}
.minitab tbody tr:nth-child(2n) td:nth-child(2n+1) {
	color: #b39700; /* noir */
	// color: #da0000;
	// 4 6
}
pluto-output table tr td table tr td.blur{
	// color: unset;
	color: transparent !important;
	// filter: blur(5px);
}

td.grandblur{
}
td.miniblur{
}
td.norbleu{
	font-weight: bold;
	color:#5668a4; /* noir */
	// color:#0064ff;
}
td.grandbleu{
	font-weight: bold;
	font-size: 18pt;
	color:#5668a4; /* noir */
	// color:#0064ff;
}

input[type="radio" i] {
		margin: 3px 3px 3px 0;
    }
.pasla{
	// visibility:hidden;
	filter: blur(3px);
}

pluto-output.rich_output,
div {
		background-color: #000;
		color: #ded8d8;
	}

// div avant Pluto v0.14.5
.CodeMirror-lines,
.CodeMirror-linenumber,
.CodeMirror-gutter-elt,
.CodeMirror-gutter,
.CodeMirror-gutters {
		background-color: #000;
		color: #ded8d8;
    	border-right: solid 1px #000;
	}

code:not(pre code),
pluto-output.rich_output code {
    // padding: 3px;
    // border-radius: 2px;
    // background-color: #e4e4e4;
    background-color: #000;
    // border-top: solid 1px #9b9f9f;
    // border-left: solid 1px #9b9f9f;
	// box-shadow: 2px 2px #9b9f9f;
	// // box-shadow: 0.5px 0.5px 0px 1px #9b9f9f;
    border: solid 1px #9b9f9f;
	color: #9b9f9f;
} 
tr#lignenonvisible {
	border-top: medium solid black !important;
}
</style>`;
//////////////////////////////////////////////////////////////////////////////////////////
const plutôtblanc = `<style id="cestblanc">
/*///////////  Pour le sudoku  //////////////*/

#taide,
#tesfoot,
#va_et_vient {
	user-select: none;
}
// #sudokufini {cursor: pointer;}
select{
  padding:10px;
}
table{
  width:0 !important;
  height:0 !important;
}
pluto-output table {
    border: medium hidden #000 !important;
	margin-block-start: 0;
	margin-block-end: 0;
}
pluto-output table.minitab {
	border-spacing: 0 !important;
    border: 0 !important;
	// margin: 1px !important;
	margin: auto !important;
}
tr {
  border:0 !important;
  width:0
}

td.even-color{
	// background-color:#000; /* noir */
	text-align:center;
	font-size:14pt;
	width:38px; 
  	height:38px;
	// border:1px solid #ccc; /* noir */
	border:1px solid black;
	padding: 0;
}

td.odd-color{
	// background-color:#222; /* noir */
	background-color:#f2f2f2;
	text-align:center;
	font-size:14pt;
	// border:1px solid #ccc; /* noir */
	border:1px solid black;
	width:38px; 
  	height:38px;	
	padding: 0;			  
}
input#pour-définir-le-sudoku-initial {
	background-color:transparent;
	border:0;
	margin-left:6px;
}
td input{
  text-align:center;
  font-size:14pt;
  width:100% !important;
  height:100% !important;
  background-color:transparent;
  border:0;
	// color:#aaa; /* noir */
}
td { min-width: 38px; }

pluto-output table tr td.blur{
	color: transparent;
	user-select: none;
	// filter: blur(5px);
}

td.mini{
	min-width:15px; 
	// height:15px;
	// color: #b39700;
	padding: 0;
}
.minitab tbody tr:nth-child(2n+1) td:nth-child(2n+1) {
	// color: #e6c300; /* noir */
	color: #af0000;
	// 1 3 7 9
}
.minitab tbody tr:nth-child(2n) td:nth-child(2n) {
	// color: #e6c300; /* noir */
	color: #af0000;
	// 5
}
.minitab tbody tr:nth-child(2n+1) td:nth-child(2n) {
	// color: #b39700; /* noir */
	color: #da0000;
	// 2 8
}
.minitab tbody tr:nth-child(2n) td:nth-child(2n+1) {
	// color: #b39700; /* noir */
	color: #da0000;
	// 4 6
}
pluto-output table tr td table tr td.blur{
	// color: unset;
	color: transparent !important;
	// filter: blur(5px);
}

td.grandblur{
}
td.miniblur{
}
td.norbleu{
	font-weight: bold;
	// color:#5668a4; /* noir */
	color:#0064ff;
}
td.grandbleu{
	font-weight: bold;
	font-size: 18pt;
	// color:#5668a4; /* noir */
	color:#0064ff;
}

input[type="radio" i] {
		margin: 3px 3px 3px 0;
    }
.pasla{
	// visibility:hidden;
	filter: blur(3px);
}
/* noir */ /*
pluto-output.rich_output,
div {
		background-color: #000;
		color: #ded8d8;
	}

// div avant Pluto v0.14.5
.CodeMirror-lines,
.CodeMirror-linenumber,
.CodeMirror-gutter-elt,
.CodeMirror-gutter,
.CodeMirror-gutters {
		background-color: #000;
		color: #ded8d8;
    	border-right: solid 1px #000;
	}

code:not(pre code),
pluto-output.rich_output code {
    // padding: 3px;
    // border-radius: 2px;
    // background-color: #e4e4e4;
    background-color: #000;
    // border-top: solid 1px #9b9f9f;
    // border-left: solid 1px #9b9f9f;
	// box-shadow: 2px 2px #9b9f9f;
	// // box-shadow: 0.5px 0.5px 0px 1px #9b9f9f;
    border: solid 1px #9b9f9f;
	color: #9b9f9f;
} */
tr#lignenonvisible {
	border-top: medium solid white !important;
}
</style>`;
var plutôtstyle = html`<span id="stylebn">${plutôtnoir}</span>`;
function noiroublanc() { 
	var stylebn = document.getElementById("stylebn");
	var cestblanc = document.getElementById("cestblanc");
	var BN = document.getElementById("BN");
	var BoN = document.getElementById("BoN");
	if (cestblanc) { 
		stylebn.innerHTML = plutôtnoir;
		BN.innerHTML = "😎";
		BoN.innerHTML = "😎";
	} else {
		stylebn.innerHTML = plutôtblanc;
		BN.innerHTML = "😉";
		BoN.innerHTML = "😉";
	};
};
// document.getElementById("BN").removeEventListener("click", noiroublanc);
document.getElementById("BN") ? document.getElementById("BN").addEventListener("click", noiroublanc) : true;
document.getElementById("BoN") ? document.getElementById("BoN").addEventListener("click", noiroublanc) : true;
document.getElementById("Bonus").addEventListener("click", noiroublanc);
return plutôtstyle;
</script>"""); pourvoirplutôt = HTML(raw"""<script>
const plutôtstylé = `<link rel="stylesheet" href="./hide-ui.css" id="cachémoiplutôt"><style>
@media screen and (any-pointer: fine) {
    pluto-cell > pluto-runarea {
        // opacity: 0.5;
        opacity: 0;
        /* to make it feel smooth: */
        transition: opacity 0.25s ease-in-out;
    }
    pluto-cell > pluto-runarea > button:hover,
    pluto-cell:hover > pluto-runarea {
        opacity: 1;
        /* to make it feel snappy: */
        transition: opacity 0.05s ease-in-out;
    }
  //  pluto-cell > pluto-shoulder > button:hover {
  //      opacity: 0;
  //      /* to make it feel snappy: */
  //      transition: opacity 0.05s ease-in-out;
  //  } 
}

pluto-cell:not(.show_input) > pluto-runarea .runcell {
    display: none !important;
}
pluto-cell:not(.show_input) > pluto-runarea,
pluto-cell > pluto-runarea {
    display: block !important;
	background-color: unset;
}
preamble {
    display: none !important;
}
main {
	margin: 0 !important;
    padding: 0 !important;
    // padding-bottom: 4rem !important;
}
pluto-shoulder {
	// display: block !important;
	visibility:hidden;
    // left: -22px;
	// width: 0;
	// // width: 22px;
	// opacity: 0;
}
</style>`;
var stylécaché = html`<span id="stylé">${plutôtstylé}</span>`;
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
</script>"""); calepin = HTML(raw"<script>return html`<a href=${JSON.stringify(window.location.href).search('.html')>1 ? JSON.stringify(window.location.href).replace('html', 'jl') : JSON.stringify(window.location.href).replace('edit', 'notebookfile')} target='_blank' download>${document.title.replace('🎈 ','').replace('— Pluto.jl','')}</a>`;</script>"); pourgarderletemps = HTML(raw"""<script>
	function générateurDeCodeClé() {
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
	</script>"""); bonusetastuces = md"""#### $(html"<div id='Bonus' style='user-select: none; margin-top: 17px !important;'>Bonus : le sudoku en cours plus tard...</div>") 
Je conseille de garder le code du sudoku en cours (en cliquant, la copie est automatique ⚡). \
$(html"<input type=button id='clégén' value='Copier le code à garder :)'><input id='pour-définir-le-sudoku-initial' type='text' style='font-size: x-small; margin-right: 2px; max-width: 38px;' />") **Note** : à coller dans un bloc-notes par exemple. 

##### ...à retrouver comme d'autres vieux sudoku : 

Retrouver et copier le code qui fut gardé (cf. note ci-dessus). \
Ensuite, dans une (nouvelle) session, cliquer dans _`Enter cell code...`_ tout en bas ↓ et coller le code. \
Enfin, lancer le code avec le bouton ▶ tout à droite, qui clignote justement. \
Ce vieux sudoku est restoré en place du sudoku initial ! (et de [retour en haut ↑](#ModifierInit) de la page). 
	
$(html"<details open><summary style='list-style: none;'><h6 id='BonusAstuces' style='display:inline-block;user-select: none;'> Autres petites astuces :</h6></summary><style>details[open] summary::after {content: ' (cliquer ici pour les cacher)';} summary:not(details[open] summary)::after {content: ' (cliquer ici pour les revoir)';}</style>")
   1. Modifier le premier sudoku (à vider si besoin), cocher ce que l'on souhaite; le sudoku du dessous répond aux ordres. Cocher `😉 Cachée` pour revoir les indications sur l'emploi des cases à cocher.
   2. En réalité en dehors de cellule ou de case, le fait de coller (même en [haut](#BN) de la page) crée une cellule tout en bas (en plus). Cela peut faire gagner un peu de temps. On peut mettre plusieurs vieux sudokus : cependant seul le dernier, où le bouton ▶ fut appuyé, est pris en compte. \
   3. Pour information, la fonction **vieuxSudoku!()** ou **vieux()** sans paramètre permet de générer un sudoku aléatoire. $(html"<br>") En mettant uniquement un nombre en paramètre, par exemple **vieuxSudoku!(62)** : ce sera le nombre de cases vides du sudoku aléatoire construit. $(html"<br>") Enfin, en mettant un intervalle, sous la forme **début : fin**, par exemple **vieuxSudoku!(1:81)** : un nombre aléatoire dans cet intervalle sera utilisé. Pour tous ces sudokus aléatoires, le fait de recliquer sur le bouton ▶ en génère un neuf.
   4. Il est possible de bouger avec les flèches, aller à la ligne suivante automatiquement (à la _[Snake](https://www.google.com/search?q=Snake)_). Il y a aussi des raccourcis, comme `H` = haut, `V` ou `G` = gauche, `D` `J` `N` = droite, `B` = bas. Ni besoin de pavé numérique, ni d'appuyer sur _Majuscule_, les touches suivantes sont idendiques `1234 567 890` = `AZER TYU IOP` = `&é"' (-è _çà`. 
   5. Il est possible de **remonter la solution** au lieu du sudoku modifiable en cliquant sur l'entête [Sudoku initial ⤴ (modifiable) et sa solution](#va_et_vient). On peut ensuite l'enlever pour revenir au sudoku modifiable, ↪ en cliquant sur le texte sous la solution remontée.
   6. Il est possible de voir ce programme en _Julia_ ([cf. wikipédia](https://fr.wikipedia.org/wiki/Julia_(langage_de_programmation))), d'abord en cliquant sur $(html"<input type=button id='plutot' value='Ceci ✨'>") pour basculer l'interface de _Pluto.jl_, puis en cliquant sur l'œil 👁 à côté de chaque cellule. $(html"<br>") Il est aussi possible de télécharger ce calepin $calepin
   7. Enfin, passer en style **sombre** ou **lumineux** en cliquant sur [**Bonus**](#Bonus) ou $coool [tout en haut](#BN) :)
$(html"</details>")
$pourvoirplutôt 
$stylélàbasavecbonus
$pourgarderletemps
	"""

# ╔═╡ 98f8cc2c-3a84-484a-b5cf-590b3f6a8fd0


# ╔═╡ Cell order:
# ╟─96d2d3e0-2133-11eb-3f8b-7350f4cda025
# ╟─caf45fd0-2797-11eb-2af5-e14c410d5144
# ╟─81bbbd00-2c37-11eb-38a2-09eb78490a16
# ╟─a038b5b0-23a1-11eb-021d-ef7de773ef0e
# ╟─7cce8f50-2469-11eb-058a-099e8f6e3103
# ╟─bba0b550-2784-11eb-2f58-6bca9b1260d0
# ╟─b2cd0310-2663-11eb-11d4-49c8ce689142
# ╟─4c810c30-239f-11eb-09b6-cdc93fb56d2c
# ╟─e986c400-60e6-11eb-1b57-97ba3089c8c1
# ╠═98f8cc2c-3a84-484a-b5cf-590b3f6a8fd0
# ╟─43ec2840-239d-11eb-075a-071ac0d6f4d4
