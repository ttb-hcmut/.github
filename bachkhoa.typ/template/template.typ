#let doc(
	department: none,
	content
) = {
	set page(
		paper: "a4",
		numbering: "1",
		margin: (
			x: 2.5cm,
			bottom: 2.2cm,
		),
		header: context {
			if counter(page).get().first() > 1 [#rect(stroke: (bottom: 1pt))[
				HCMUT -
				#if department == none [(Set `department:` here)] else [#department]
				#h(1fr)
				Course: Computer Graphics
			]]
		},
		footer: context {
			if counter(page).get().first() > 1 [
				#h(1fr) Page #counter(page).get().first()
			] else [
				#align(center)[#counter(page).get().first()]
			]
		}
	)
	set par(justify: true)
	set text(size: 11pt, font: "New Computer Modern")
	show heading: it => [
		#set text(size: 16pt)
		#v(35pt)
		#it.body
	]
	content
}

#let cover1(
  title_,
  subtitle: none,
  instructor: none,
  date: none,
  version: none,
	department: none,
) = {
  let bold(content) = {
    text(weight: "bold", content)
  }

	let supernormalsize(content) = {
		text(size: 16pt, weight: "extralight", content)
	}

	let normalsize(content) = {
		text(size: 14pt, weight: "extralight", content)
	}

	set par(justify: false)

  align(center)[
    #v(1.2cm)
    
    #image("hcmut-withring.svg", width: 3.2cm)

    #v(0.5cm)
    
    #text(size: 20pt, weight: "bold", upper(title_))
    
		#if subtitle != none [
			#text(subtitle)
		]
    
    #supernormalsize([Semester 251 — Academic Year 2025-2026])

    #normalsize([
			#if department == none [(Set `department:` here)] else [#department]
			#linebreak()
			Ho Chi Minh University of Technology (HCMUT), VNU-HCM])

    #if instructor != none [
      #normalsize([#bold[Instructor:] #instructor])
    ]

    #normalsize(
			if date == none [(Set `date:` here)] else [#date.display("[month repr:long] [day], [year]")]
		)

    #if version != none [
      #normalsize(bold[Current version: ] + version)
    ]
  ]
}

#let cover = cover1
