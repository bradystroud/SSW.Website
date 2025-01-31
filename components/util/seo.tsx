import React from "react";
import { NextSeo, NextSeoProps } from "next-seo";
import { NEXT_SEO_DEFAULT } from "../../next-seo.config";

export const SEO = ({ seo }) => {
	if (!seo) return null;

	let seoPartial: Partial<NextSeoProps> = {};

	seoPartial = {
		title: seo.title,
		description: seo.description,
		canonical: seo.canonical,
		openGraph: {
			title: seo.title,
			description: seo.description,
			url: seo.canonical,
			images: seo.images ?? null,
		},
		twitter: {
			site: seo.canonical,
		},
	};

	// Remove null values from SEO object
	Object.keys(seoPartial).forEach((key) => {
		if (!seoPartial[key]) {
			delete seo[key];
		}
	});

	const seoProps = {
		...NEXT_SEO_DEFAULT,
		...seoPartial,
	};

	return <NextSeo {...seoProps} />;
};

export const seoSchema = {
	type: "object",
	label: "SEO Values",
	name: "seo",
	fields: [
		{
			type: "string",
			label: "Title",
			name: "title",
		},
		{
			type: "string",
			label: "Description",
			name: "description",
			component: "textarea",
		},
		{
			type: "string",
			label: "Canonical URL",
			name: "canonical",
		},
		{
			label: "Images",
			name: "images",
			list: true,
			type: "object",
			ui: {
				itemProps: (item) => {
					return { label: item.url };
				},
				defaultItem: {
					url: "/images/ssw-og.jpg",
					width: 1200,
					height: 630,
					alt: "SSW Consulting - Enterprise Software Development",
				},
			},
			fields: [
				{
					type: "image",
					label: "Image Url",
					name: "url",
					require: true,
				},
				{
					type: "number",
					label: "Width (px)",
					name: "width",
				},
				{
					type: "number",
					label: "Height (px)",
					name: "height",
				},
				{
					type: "string",
					label: "Image Alt Text",
					name: "alt",
				},
			],
		},
	],
};
